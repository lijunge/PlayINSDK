//
//  PIStream.m
//  playin
//
//  Created by 城门虾米 on 2019/5/20.
//  Copyright © 2019 lijunge. All rights reserved.
//

#import "PIStream.h"
#import "PISocket.h"
#import "PIUtil.h"

@implementation PIStream
{
    PISocket *_piSocket;
    NSString *_deviceName;
    NSString *_host;
    NSInteger _port;
    NSString *_token;
    int     _duration;
    BOOL    _connected;
    BOOL    _registered;
    BOOL    _tokenTimeout;
    dispatch_queue_t _delegateQueue;
    dispatch_source_t _tokenEndTimer;
}

- (instancetype)init {
    
    if (self = [super init]) {
        NSLog(@"[PIStream] init");
        _connected = NO;
        _registered = NO;
        _tokenTimeout = NO;
        _delegateQueue = dispatch_queue_create("tech.playin.pistream.delegate", NULL);
        _piSocket = [[PISocket alloc] initWithDelegate:self delegateQueue:_delegateQueue];
        _tokenEndTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _delegateQueue);
        dispatch_source_set_event_handler(_tokenEndTimer, ^{
            self->_tokenTimeout = YES;
            [self stopStream];
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamEnded:)]) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"token time out" forKey:NSLocalizedDescriptionKey];
                [self.delegate onPIStreamEnded:[NSError errorWithDomain:@"pistream" code:-1 userInfo:userInfo]];
            }
        });
    }
    return self;
}


- (BOOL)startStreamWithToken:(nonnull NSString *)token deviceName:(nonnull NSString *)deviceName host:(nonnull NSString *)host port:(NSInteger)port duration:(uint)duration {
    
    if (![PIUtil validStr:token]) {
        NSLog(@"[PIStream] token invalid");
        return NO;
    }
    if (![PIUtil validStr:deviceName]) {
        NSLog(@"[PIStream] deviceName invalid");
        return NO;
    }
    if (![PIUtil validStr:host]) {
        NSLog(@"[PIStream] host invalid");
        return NO;
    }
    if (port <= 0 || port >= 65535) {
        NSLog(@"[PIStream] port invalid");
        return NO;
    }
    
    self->_host = host;
    self->_port = port;
    self->_token = token;
    self->_deviceName = deviceName;
    self->_duration = duration;
    
    //self->_duration = 50;
    NSError *error = nil;
    [_piSocket connectToHost:host onPort:port withTimeout:3 error:&error];
    
    return YES;
}


- (void)sendTouchData:(NSData *)touchData {
    [_piSocket sendStreamData:touchData];
}

- (void)stopStream {
    [_piSocket disconnect];
}


- (void) registerStream {

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:self->_token forKey:@"token"];
    [params setValue:self->_deviceName forKey:@"device_name"];
    [params setValue:@1 forKey:@"os_type"];
    [params setValue:@"avcc" forKey:@"coder"];
    [self->_piSocket sendMessageWithMsgID:MsgID_Req_User_Connect Data:params];
//    dispatch_after(DISPATCH_TIME_NOW + 5, _delegateQueue, ^{
//
//        [self->_piSocket sendMessageToAndroid];
//    });
}

- (void)socketDidConnect:(PISocket *)sock {
    NSLog(@"[PIStream] socketDidConnect");
    _connected = TRUE;
    [self registerStream];
    
    dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self->_duration * NSEC_PER_SEC));
    dispatch_source_set_timer(_tokenEndTimer, tt, DISPATCH_TIME_FOREVER, 0);
    dispatch_resume(_tokenEndTimer);
    
}

- (void)socketDidDisconnect:(PISocket *)sock withError:(nullable NSError *)err {
    NSLog(@"[PIStream] socketDidDisconnect err = %@", err);
    _connected = NO;
    _registered = NO;
    if (_tokenEndTimer) {
        dispatch_source_cancel(_tokenEndTimer);
        _tokenEndTimer = NULL;
    }
    if (!_tokenTimeout) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamEnded:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"socket disconnect" forKey:NSLocalizedDescriptionKey];
            [self.delegate onPIStreamEnded:[NSError errorWithDomain:@"pistream" code:-1 userInfo:userInfo]];
        }
    }
}

- (void)socket:(PISocket *)sock didReadPacket:(NSData *)packet {
    
    pi_packet_t *pkt = (pi_packet_t*)packet.bytes;
    if (pkt->pkt_type == 1) {
        NSLog(@"[PIStream] pkt->pkt_type == 1");
        pi_packet_control_t* control = (pi_packet_control_t*)pkt->data;
        if (control->msgid == MsgID_Res_User_Connect) {
            NSLog(@"[PIStream] MsgID_Res_User_Connect");
            NSData * data = [NSData dataWithBytes:control->buf length:pkt->length -6];
            NSError *err = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0x0 error:&err];
            if (err) {
                NSLog(@"[PIStream] json error: %@", err);
                if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamRegisterFailure:)]) {
                    [self.delegate onPIStreamRegisterFailure:err.description];
                }
                return;
            }
            
            id codeObj = [dict valueForKey:@"code"];
            if (![PIUtil validObj:codeObj]) {
                NSLog(@"[PIStream] code params invalid");
                if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamRegisterFailure:)]) {
                    [self.delegate onPIStreamRegisterFailure:@"code params invalid"];
                }
                return;
            }
            
            int code = [codeObj intValue];
            if (code != 0) {
                NSLog(@"code != 0");
                NSString *errStr = [dict valueForKey:@"error"];
                if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamRegisterFailure:)]) {
                    [self.delegate onPIStreamRegisterFailure:errStr];
                }
                return;
            }
            NSLog(@"[PIStream] dict: %@", dict);
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamRegisterSuccess:)]) {
                [self.delegate onPIStreamRegisterSuccess:dict];
            }
            _registered = YES;
        }
    }
    
    if (pkt->pkt_type == 2) {
        uint8_t stream_type = *(uint8_t *)(pkt->data);
        NSData * data = [NSData dataWithBytes:pkt->data + 1 length:pkt->length - 1];
        if (stream_type == pi_stream_h264 || stream_type == pi_stream_androidVideoStart) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamReceivedVideoData:)]) {
                [self.delegate onPIStreamReceivedVideoData:data];
            }
        } else if (stream_type == pi_stream_aac) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPIStreamReceivedAudioData:)]) {
                [self.delegate onPIStreamReceivedAudioData:data];
            }
        }
    }
}

@end
