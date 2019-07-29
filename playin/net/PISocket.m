//
//  PISocket.m
//  sdk
//
//  Created by 城门虾米 on 2019/5/9.
//  Copyright © 2019 虾米城门. All rights reserved.
//

#import "PISocket.h"
#import "Packet.h"

#include <string.h>
#include <unistd.h>

#include <fcntl.h>
#include <errno.h>

#include <sys/types.h>          /* See NOTES */
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>


NSString *const PISocketException = @"PISocketException";
NSString *const PISocketErrorDomain = @"PISocketErrorDomain";

static bool isconnected(int sockfd, fd_set *rd, fd_set *wr)
{
    if (!FD_ISSET(sockfd, rd) && !FD_ISSET(sockfd, wr)) {
        return false;
    }
    int err;
    socklen_t len = sizeof(err);
    if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &err, &len) < 0) {
        return false;
    }
    errno = err;        /* in case we're not connected */
    return err == 0;
}

int connect_timeout(int sockfd, const struct sockaddr *addr, socklen_t addrlen, struct timeval *timeout)
{
    int flags = fcntl(sockfd, F_GETFL, 0);
    if (flags == -1) {
        return -1;
    }
    if (fcntl( sockfd, F_SETFL, flags | O_NONBLOCK ) < 0) {
        return -1;
    }
    
    int status = connect(sockfd, addr, addrlen);
    if (status == -1 && errno != EINPROGRESS) {
        return -1;
    }
    if (status == 0) {
        if (fcntl(sockfd, F_SETFL, flags) <  0) {
            return -1;
        }
        return 1;
    }
    fd_set read_events;
    fd_set write_events;
    FD_ZERO(&read_events);
    FD_SET(sockfd, &read_events);
    write_events = read_events;
    int rc = select(sockfd + 1, &read_events, &write_events, NULL, timeout );
    if (rc < 0) {
        return -1;
    } else if (rc == 0) {
        return -2;
    }
    if (!isconnected(sockfd, &read_events, &write_events) )
    {
        return -1;
    }
    if ( fcntl( sockfd, F_SETFL, flags ) < 0 ) {
        return -1;
    }
    return 0;
}




@interface PIWritePacket : NSObject
{
@public
    NSData *buffer;
    NSUInteger bytesDone;
}
- (id)initWithData:(NSData *)d;
@end

@implementation PIWritePacket

- (id)initWithData:(NSData *)d
{
    if((self = [super init]))
    {
        buffer = d; // Retain not copy. For performance as documented in header file.
        bytesDone = 0;
    }
    return self;
}


@end


enum PISocketFlags
{
    kConnecting                    = 1 <<  0,  // If set, socket has been started (accepting/connecting)
    kConnected                     = 1 <<  1,  // If set, the socket is connected
    kForbidReadsWrites             = 1 <<  2,  // If set, no new reads or writes are allowed
    kReadsPaused                   = 1 <<  3,  // If set, reads are paused due to possible timeout
    kWritesPaused                  = 1 <<  4,  // If set, writes are paused due to possible timeout
    kDisconnectAfterReads          = 1 <<  5,  // If set, disconnect after no more reads are queued
    kDisconnectAfterWrites         = 1 <<  6,  // If set, disconnect after no more writes are queued
    kSocketCanAcceptBytes          = 1 <<  7,  // If set, we know socket can accept bytes. If unset, it's unknown.
    kReadSourceSuspended           = 1 <<  8,  // If set, the read source is suspended
    kWriteSourceSuspended          = 1 <<  9,  // If set, the write source is suspended
    
    kSocketHasReadEOF              = 1 << 14,  // If set, we have read EOF from socket
    kReadStreamClosed              = 1 << 15,  // If set, we've read EOF plus prebuffer has been drained
    kDealloc                       = 1 << 16,  // If set, the socket is being deallocated
    kAddedStreamsToRunLoop         = 1 << 17,  // If set, CFStreams have been added to listener thread
};

@implementation PISocket
{
    CFReadStreamRef _readStream;
    CFWriteStreamRef _writeStream;
    CFStreamClientContext _streamContext;
    
    NSMutableArray *_writeQueue;
    PIWritePacket *_currentWrite;
    
    int _socketfd;
    int _flags; ///
    
    __weak id<PISocketDelegate> _delegate;
    
    NSThread *_cfstreamThread;
    
    dispatch_queue_t _delegateQueue;
    dispatch_queue_t _socketQueue;
    dispatch_source_t _connectTimer;
    
    char  *_buffer;
    size_t _buflen;
}


static void CFWriteStreamCallback (CFWriteStreamRef stream, CFStreamEventType event, void *info)
{
    PISocket *piSocket = (__bridge PISocket *)info;
    
    switch(event) {
        case kCFStreamEventCanAcceptBytes:
        {
            dispatch_async(piSocket->_socketQueue, ^{ @autoreleasepool {
                if (piSocket->_writeStream != stream)
                    return;
                [piSocket doWriteData];
            }});
            break;
        }
        default:
        {
            NSError *error = (__bridge_transfer  NSError *)CFWriteStreamCopyError(piSocket->_writeStream);
            if (error == nil && event == kCFStreamEventEndEncountered) {
                NSString *errMsg = NSLocalizedStringWithDefaultValue(@"PISocketClosedError",
                                                                     @"PISocket", [NSBundle mainBundle],
                                                                     @"Socket closed by remote peer", nil);
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
                
                error = [NSError errorWithDomain:@"PISocketErrorDomain" code:-1 userInfo:userInfo];
            }
            
            dispatch_async(piSocket->_socketQueue, ^{ @autoreleasepool {
                
                if (piSocket->_writeStream != stream)
                    return;
                [piSocket closeWithError:error];
            }});
            break;
        }
    }
    
}

void CFReadStreamCallback(CFReadStreamRef stream, CFStreamEventType event, void *info)
{
    PISocket *piSocket = (__bridge PISocket *)info;
    switch(event) {
        case kCFStreamEventOpenCompleted: {
            NSLog(@"[PISocket] kCFStreamEventOpenCompleted");
            NSError *error = (__bridge_transfer  NSError *)CFReadStreamCopyError(stream);
            if (error) {
                NSLog(@"[PISocket] kCFStreamEventOpenCompleted %@", error);
            }
            dispatch_async(piSocket->_socketQueue, ^{
                [piSocket didConnect];
            });
            break;
        }
        case kCFStreamEventHasBytesAvailable: {
            
            dispatch_async(piSocket->_socketQueue, ^{
                [piSocket doReadData];
            });
            break;
        }
            
        default: {
            NSError *error = (__bridge_transfer  NSError *)CFReadStreamCopyError(stream);
            if (error == nil && event == kCFStreamEventEndEncountered) {
                NSString *errMsg = NSLocalizedStringWithDefaultValue(@"PISocketClosedError",
                                                                     @"PISocket", [NSBundle mainBundle],
                                                                     @"Socket closed by remote peer", nil);
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
                
                error = [NSError errorWithDomain:@"PISocketErrorDomain" code:-1 userInfo:userInfo];
            }
            
            dispatch_async(piSocket->_socketQueue, ^{ @autoreleasepool {
                
                if (piSocket->_readStream != stream)
                    return;
                [piSocket closeWithError:error];
            }});
            break;
        }
            
    }
}
+ (void)scheduleCFStreams:(PISocket *)piSocket
{
    NSLog(@"[PISocket] CFReadStreamScheduleWithRunLoop");
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFReadStreamScheduleWithRunLoop(piSocket->_readStream, runLoop, kCFRunLoopDefaultMode);
    CFWriteStreamScheduleWithRunLoop(piSocket->_writeStream, runLoop, kCFRunLoopDefaultMode);
}

+ (void)ignore:(id)_
{}

+ (void)cfstreamThreadRun {
    
    [[NSThread currentThread] setName:@"ssss"];
    
    NSLog(@"[PISocket] CFStreamThread: Started");
    
    // We can't run the run loop unless it has an associated input source or a timer.
    // So we'll just create a timer that will never fire - unless the server runs for decades.
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                     target:self
                                   selector:@selector(ignore:)
                                   userInfo:nil
                                    repeats:YES];
    
    NSThread *currentThread = [NSThread currentThread];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    
    BOOL isCancelled = [currentThread isCancelled];
    
    while (!isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        isCancelled = [currentThread isCancelled];
    }
    
    NSLog(@"[PISocket] CFStreamThread: Stopped");
}

- (void) doWriteData {
    if (_currentWrite == nil) {
        return;
    }
    
    while (CFWriteStreamCanAcceptBytes(self->_writeStream)) {
        const uint8_t *buffer = (const uint8_t *)[_currentWrite->buffer bytes] + _currentWrite->bytesDone;
        NSUInteger bytesToWrite = [_currentWrite->buffer length] - _currentWrite->bytesDone;
        
        if (bytesToWrite > SIZE_MAX) {
            bytesToWrite = SIZE_MAX;
        }
        
        ssize_t bytesWritten = CFWriteStreamWrite(self->_writeStream, buffer, bytesToWrite);
        
        if (bytesWritten < 0) {
            //        error = [self errorWithErrno:errno reason:@"Error in write() function"];
            //        [self closeWithError:[self errorWithErrno:errno reason:@"Error in write() function"]];
        } else {
            // Update total amount read for the current write
            _currentWrite->bytesDone += bytesWritten;
            
            if (_currentWrite->bytesDone == [_currentWrite->buffer length]) {
                _currentWrite = nil;
                dispatch_async(_socketQueue, ^{ @autoreleasepool{
                    [self maybeDequeueWrite];
                }});
                return;
            }
        }
    }
}


- (void) maybeDequeueWrite {
    if ((_currentWrite == nil) && _flags & kConnected) {
        if ([_writeQueue count] > 0) {
            _currentWrite = [_writeQueue objectAtIndex:0];
            [_writeQueue removeObjectAtIndex:0];
        }
    }
    
    [self doWriteData];
}

- (void)writeData:(nonnull NSData *)data {
    
    PIWritePacket *ptk = [[PIWritePacket alloc] initWithData:data];
    
    dispatch_async(self->_socketQueue, ^{ @autoreleasepool {
        [self->_writeQueue addObject:ptk];
        [self maybeDequeueWrite];
    }});
}

- (void) doReadData {
    
    if (!(_flags & kConnected)) {
        return;
    }
    
    UInt8 bytes[10240];
    while (CFReadStreamHasBytesAvailable(self->_readStream)) {
        int readLength = (int)CFReadStreamRead(self->_readStream, bytes, 10240);
        if (readLength < 0) {
            NSError* error = (__bridge_transfer NSError *)CFReadStreamCopyError(self->_readStream);
            [self closeWithError:error];
            return;
        } else if (readLength == 0) {
            
            NSString *errMsg = NSLocalizedStringWithDefaultValue(@"PISocketClosedError",
                                                                 @"PISocket", [NSBundle mainBundle],
                                                                 @"Socket closed by remote peer", nil);
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            
            [self closeWithError:[NSError errorWithDomain:PISocketErrorDomain code:-1 userInfo:userInfo]];
            return;
        }
        memcpy(_buffer + _buflen, bytes, readLength);
        _buflen += readLength;
        
        pi_packet_t * pkt = (pi_packet_t*)_buffer;
        if ( _buflen >= 5) {
            int pkt_length = pkt->length + 5;
            if (_buflen >= pkt_length) {
                NSData *data = [NSData dataWithBytes:_buffer length:pkt_length];
                dispatch_async(self->_delegateQueue, ^{
                    if ([self->_delegate respondsToSelector:@selector(socket:didReadPacket:)]) {
                        [self->_delegate socket:self didReadPacket:data];
                    }
                });
                _buflen -= pkt_length;
                memmove(_buffer, _buffer + pkt_length, _buflen);
            }
        }
    }
}

- (id)initWithDelegate:(id<PISocketDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue{
    if (self = [super init]) {
        
        self->_buffer = malloc(1024 * 1024);
        self->_buflen = 0;
        
        self->_writeQueue = [[NSMutableArray alloc] initWithCapacity:5];
        self->_currentWrite = nil;
        
        self->_delegate = delegate;
        self->_socketQueue = dispatch_queue_create("tech.playin.socket.stream", NULL);
        
        if (delegateQueue != nil) {
            self->_delegateQueue = delegateQueue;
        } else {
            self->_delegateQueue = dispatch_queue_create("tech.playin.socket.delegate", NULL);
        }
        
        
        self->_cfstreamThread = [[NSThread alloc] initWithTarget:[self class]
                                                        selector:@selector(cfstreamThreadRun)
                                                          object:nil];
        [self->_cfstreamThread start];
        
    }
    return self;
}


- (void)dealloc
{
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
    
    self->_flags |= kDealloc;
    
    dispatch_sync(_socketQueue, ^{
        [self closeWithError:nil];
    });
    
    [self->_cfstreamThread cancel]; // set isCancelled flag
    [[self class] performSelector:@selector(ignore:)
                         onThread:self->_cfstreamThread
                       withObject:[NSNull null]
                    waitUntilDone:NO];
    
    self->_cfstreamThread = nil;
    
    
    _delegate = nil;
    _delegateQueue = NULL;
    _socketQueue = NULL;
}

- (NSError *)errorWithErrno:(int)err reason:(NSString *)reason {
    
    NSString *errMsg = [NSString stringWithUTF8String:strerror(err)];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errMsg, NSLocalizedDescriptionKey,
                              reason, NSLocalizedFailureReasonErrorKey, nil];
    
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:userInfo];
}

- (NSError *)otherError:(NSString *)errMsg {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:userInfo];
}



- (void) didConnect {
    
    self->_flags = kConnected;
    
    CFStreamCreatePairWithSocket(NULL, (CFSocketNativeHandle)_socketfd, &_readStream, &_writeStream);
    if (_readStream)
        CFReadStreamSetProperty(_readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanFalse);
    if (_writeStream)
        CFWriteStreamSetProperty(_writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanFalse);
    
    if (_readStream == NULL || _writeStream == NULL) {
        [self closeWithError:[self otherError:@"Error creating CFStreams"]];
        return;
    }
    
    _streamContext.version = 0;
    _streamContext.info = (__bridge void *)(self);
    _streamContext.retain = nil;
    _streamContext.release = nil;
    _streamContext.copyDescription = nil;
    
    CFOptionFlags readStreamEvents = kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventHasBytesAvailable;
    if (!CFReadStreamSetClient(_readStream, readStreamEvents, &CFReadStreamCallback, &_streamContext)) {
        [self closeWithError:[self otherError:@"Error in CFStreamSetClient"]];
        return;
    }
    
    CFOptionFlags writeStreamEvents = kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventCanAcceptBytes;
    if (!CFWriteStreamSetClient(_writeStream, writeStreamEvents, &CFWriteStreamCallback, &_streamContext)) {
        [self closeWithError:[self otherError:@"Error in CFStreamSetClient"]];
        return;
    }
    
    [self addStreamsToRunLoop];
    dispatch_async(_delegateQueue, ^{
        
        if ([self->_delegate respondsToSelector:@selector(socketDidConnect:)]) {
            [self->_delegate socketDidConnect:self];
        }
        
        
    });
}


- (BOOL)connectToHost:(nonnull NSString *)host onPort:(uint16_t)port withTimeout:(int)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)err {
    
    if (self->_flags & kConnecting || self->_flags & kConnected) {
        return NO;
    };
    
    self->_flags = kConnecting;
    
    dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalConcurrentQueue, ^{
        self->_socketfd = socket(AF_INET, SOCK_STREAM, 0);
        int nosigpipe = 1;
        setsockopt(self->_socketfd, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
        
        struct sockaddr_in nativeAddr4;
        nativeAddr4.sin_len         = sizeof(struct sockaddr_in);
        nativeAddr4.sin_family      = AF_INET;
        nativeAddr4.sin_port        = htons(port);
        nativeAddr4.sin_addr.s_addr = inet_addr([host UTF8String]);
        memset(&(nativeAddr4.sin_zero), 0, sizeof(nativeAddr4.sin_zero));
        
        struct timeval tv = { (long)timeout, 0 };
        
        int result = connect_timeout(self->_socketfd, (const struct sockaddr *)&nativeAddr4, sizeof(nativeAddr4), &tv);
        int err = errno;
        dispatch_async(self->_socketQueue, ^{
            
            if (result == 0) {
                [self didConnect];
            } else if (result == -2) {
                [self closeWithError:[self otherError:@"timeout in connect() function"]];
            } else {
                NSError *error = [self errorWithErrno:err reason:@"Error in connect() function"];
                [self closeWithError:error];
            }
        });
    });
    
    return YES;
}


- (void)disconnect
{
    dispatch_sync(_socketQueue, ^{
        if (self->_flags & kConnected) {
            [self closeWithError:nil];
        }
    });
}


+ (void)unscheduleCFStreams:(PISocket *)piSocket
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    
    if (piSocket->_readStream)
        CFReadStreamUnscheduleFromRunLoop(piSocket->_readStream, runLoop, kCFRunLoopDefaultMode);
    
    if (piSocket->_writeStream)
        CFWriteStreamUnscheduleFromRunLoop(piSocket->_writeStream, runLoop, kCFRunLoopDefaultMode);
}

- (void)addStreamsToRunLoop {
    
    if (!(self->_flags & kAddedStreamsToRunLoop)) {
        
        dispatch_async(self->_socketQueue, ^{
            [[self class] performSelector:@selector(scheduleCFStreams:)
                                 onThread:self->_cfstreamThread
                               withObject:self
                            waitUntilDone:YES];
            self->_flags |= kAddedStreamsToRunLoop;
            
            
            if (!CFReadStreamOpen(self->_readStream)) {
                [self closeWithError:[self otherError:@"Error creating CFStreams"]];
                return;
            }
            if (!CFWriteStreamOpen(self->_writeStream)) {
                [self closeWithError:[self otherError:@"Error creating CFStreams"]];
                return;
            }
        });
    }
}

- (void)removeStreamsFromRunLoop {
    
    if (self->_flags & kAddedStreamsToRunLoop) {
        
        [[self class] performSelector:@selector(unscheduleCFStreams:)
                             onThread:_cfstreamThread
                           withObject:self
                        waitUntilDone:YES];
        
        self->_flags &= ~kAddedStreamsToRunLoop;
    }
}


- (void)closeWithError:(NSError *)error {
    NSLog(@"[PISocket] closeWithError %@",error);
    
    close(_socketfd);
    
    if (_readStream || _writeStream) {
        if (_readStream) {
            CFReadStreamSetClient(_readStream, kCFStreamEventNone, NULL, NULL);
            CFReadStreamClose(_readStream);
            CFRelease(_readStream);
            _readStream = NULL;
        }
        if (_writeStream) {
            CFWriteStreamSetClient(_writeStream, kCFStreamEventNone, NULL, NULL);
            CFWriteStreamClose(_writeStream);
            CFRelease(_writeStream);
            _writeStream = NULL;
        }
    }
    
    if (_flags & kConnected) {
        [self removeStreamsFromRunLoop];
        if (_delegateQueue && [_delegate respondsToSelector: @selector(socketDidDisconnect:withError:)]) {
            __strong id theSelf = (self->_flags & kDealloc) ? nil : self;
            dispatch_async(_delegateQueue, ^{
                [self->_delegate socketDidDisconnect:theSelf withError:error];
            });
        }
    }
    _flags = 0;
}

- (void)sendMessageWithMsgID:(int)msgid Data:(NSDictionary*)dict {
    
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0x0 error:&err];
    
    char buf[1024] = {0};
    pi_packet_t *pkt = (pi_packet_t*)buf;
    pkt->pkt_type = 0x01;
    pkt->length = (uint32_t)(sizeof(pi_packet_control_t) + data.length);
    
    pi_packet_control_t *msg = (pi_packet_control_t*)pkt->data;
    msg->msgid = MsgID_Req_User_Connect;
    msg->packetid = 0x00;
    memcpy(msg->buf, data.bytes, data.length);
    
    unsigned long data_len = sizeof(pi_packet_t) + sizeof(pi_packet_control_t) + data.length;
    
    [self writeData:[NSData dataWithBytes:pkt length:data_len]];
}

- (void)sendStreamData:(NSData*)data {
    
    NSUInteger touchDataLen = data.length;
    char buf[1024] = {0};
    pi_packet_t *pkt = (pi_packet_t*)buf;
    pkt->pkt_type = 0x02; // stream packet
    pkt->length = (uint32_t)(sizeof(pi_packet_stream_t) + touchDataLen);
    
    pi_packet_stream_t *stream = (pi_packet_stream_t *)pkt->data;
    stream->streamtype = pi_stream_touch;
    memcpy(stream->buf, data.bytes, touchDataLen);
    
    unsigned long pkt_len = sizeof(pi_packet_t)+sizeof(pi_packet_stream_t)+touchDataLen;
    [self writeData:[NSData dataWithBytes:pkt length:pkt_len]];
}

- (void)sendMessageToAndroid {
    
    NSUInteger touchDataLen = 0;
    char buf[1024] = {0};
    pi_packet_t *pkt = (pi_packet_t*)buf;
    pkt->pkt_type = 0x02; // stream packet
    pkt->length = (uint32_t)(sizeof(pi_packet_stream_t) + touchDataLen);
    
    pi_packet_stream_t *stream = (pi_packet_stream_t *)pkt->data;
    stream->streamtype = pi_stream_androidVideoStart;
   
    unsigned long pkt_len = sizeof(pi_packet_t)+sizeof(pi_packet_stream_t)+touchDataLen;
    [self writeData:[NSData dataWithBytes:pkt length:pkt_len]];
}


@end





