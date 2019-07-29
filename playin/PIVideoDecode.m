//
//  PIVideoDecode.m
//  playin
//
//  Created by A on 2017/10/17.
//  Copyright © 2017年 A. All rights reserved.
//

#import "PIVideoDecode.h"
#import <VideoToolbox/VideoToolbox.h>

@interface PIVideoDecode ()
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;
@property (nonatomic, strong) NSData *spspps;
@property (nonatomic, strong) NSLock *lock;
@property (atomic, assign) CMVideoFormatDescriptionRef vFormatDescription;
@property (atomic, assign) VTDecompressionSessionRef session;
@property (atomic, copy) PIVideoDecodeCompletionHandle vDecodeCompHandle;
@end

@implementation PIVideoDecode {
    
}

+ (PIVideoDecode *)shared {
    
    static PIVideoDecode *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PIVideoDecode alloc] init];
    });
    return instance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        NSLog(@"[PIVideoDecode] init");
        [self addObservers];
        //iOS
        NSData *sps = [self dataFromHexString:@"274d001e ab40c02a f2da"];
        NSData *pps = [self dataFromHexString:@"28ee3c30"];
        //Android
//        NSData *sps = [self dataFromHexString:@"6742C0298D681705165E01E1108D40"];
//        NSData *pps = [self dataFromHexString:@"68CE01A835C8"];
        self.lock = [NSLock new];
        [self updateSps:sps pps:pps];
    }
    return self;
}

- (BOOL)updateSps:(NSData *)sps pps:(NSData *)pps {
    
    //NSLog(@"[PIVideoDecode] update sps: %@ pps: %@", sps, pps);
    [self.lock lock];
    self.vFormatDescription = [self videoFormatDescriptionFromSps:sps pps:pps];
    if (self.vFormatDescription == nil) {
        NSLog(@"[PIVideoDecode] updateSpsPps failed: vFormatDescription create failed");
        [self.lock unlock];
        return NO;
    }
    self.session = [self decompressionSessionFrom:self.vFormatDescription];
    if (self.session == nil) {
        NSLog(@"[PIVideoDecode] updateSpsPps failed: session create failed");
        [self.lock unlock];
        return NO;
    }
    [self.lock unlock];
    return YES;
}

- (CMFormatDescriptionRef)videoFormatDescriptionFromSps:(NSData *)sps pps:(NSData *)pps {
    
    if (sps == nil || pps == nil) {
        NSLog(@"[PIVideoDecode] create videoFormatDescription error: sps or pps is nil");
        return nil;
    }
    
    const uint8_t * const parameterSetPointers[2] = { (const uint8_t*)[sps bytes], (const uint8_t*)[pps bytes] };
    const size_t parameterSetSizes[2] = { [sps length], [pps length] };
    CMFormatDescriptionRef format = nil;
    CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                        2,
                                                        parameterSetPointers,
                                                        parameterSetSizes,
                                                        4,
                                                        &format);
    
    return format;
}

- (CMSampleBufferRef)sampleBufferFromVideoFormatDescription:(CMFormatDescriptionRef)format naluData:(NSData *)nalu {
    
    OSStatus status;
    CMBlockBufferRef blockBuffer = nil;
    CMSampleBufferRef sampleBuffer = nil;
    
    status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                (void *)nalu.bytes,
                                                nalu.length,
                                                kCFAllocatorNull,
                                                nil,
                                                0,
                                                nalu.length,
                                                false,
                                                &blockBuffer);
    
    if (!status) {
        status = CMSampleBufferCreate(nil,
                                      blockBuffer,
                                      true,
                                      0,
                                      0,
                                      format,
                                      1,
                                      0,
                                      nil,
                                      0,
                                      nil,
                                      &sampleBuffer);
    }
    
    CFRelease(blockBuffer);
    if (status == 0) {
        return sampleBuffer;
    } else {
        return nil;
    }
}

void printErr(OSStatus status)
{
    NSString *str = nil;
    switch (status) {
        case kVTVideoDecoderBadDataErr:
            str = @"BadDataErr";
            break;
        case kVTInvalidSessionErr:
            str = @"InvalidSessionErr";
            break;
        case kVTCouldNotFindVideoDecoderErr:
            str = @"CouldNotFindVideoDecoderErr";
            break;
        case kVTVideoDecoderRemovedErr:
            str = @"VideoDecoderRemovedErr";
            break;
        case kVTParameterErr:
            str = @"ParameterErr";
            break;
        case kVTCouldNotCreateInstanceErr:
            str = @"CouldNotCreateInstanceErr";
            break;
        case kVTVideoDecoderUnsupportedDataFormatErr:
            str = @"VideoDecoderUnsupportedDataFormatErr";
            break;
        case kVTVideoDecoderNotAvailableNowErr:
            str = @"VideoDecoderNotAvailableNowErr";
            break;
        default:
            str = [NSString stringWithFormat:@"%d", (int)status];
            break;
    }
    
    NSLog(@"[PIVideoDecode] decode err: %@", str);
}

// VTDecompressionOutputCallback
void decompressionSessionDecodeFrameCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                             void * CM_NULLABLE sourceFrameRefCon,
                                             OSStatus status,
                                             VTDecodeInfoFlags infoFlags,
                                             CM_NULLABLE CVImageBufferRef imageBuffer,
                                             CMTime presentationTimeStamp,
                                             CMTime presentationDuration ) {
    
    if (status != noErr) {
        printErr(status);
        return;
    }
    
    //PIVideoDecode *vDecode = (__bridge PIVideoDecode *)decompressionOutputRefCon;
    
    CVPixelBufferRetain(imageBuffer);
    //if (vDecode->vDecodeCompHandle) vDecode->vDecodeCompHandle(imageBuffer);
    if (PIVideoDecode.shared.vDecodeCompHandle) {
        PIVideoDecode.shared.vDecodeCompHandle(imageBuffer);
    }
    CVPixelBufferRelease(imageBuffer);
}

void CFDictionarySetSInt32(CFMutableDictionaryRef dictionary, CFStringRef key, SInt32 numberSInt32) {
    
    CFNumberRef number;
    number = CFNumberCreate(NULL, kCFNumberSInt32Type, &numberSInt32);
    CFDictionarySetValue(dictionary, key, number);
    CFRelease(key);
    CFRelease(number);
}

- (VTDecompressionSessionRef)decompressionSessionFrom:(CMFormatDescriptionRef)format {
    
    if (format == nil) {
        NSLog(@"[PIVideoDecode] create decompression failed: format is nil");
        return nil;
    }
    
    CFMutableDictionaryRef destPixelBufferAttr = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetSInt32(destPixelBufferAttr, kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    //CFDictionarySetSInt32(destPixelBufferAttr, kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    //CFDictionarySetValue(destPixelBufferAttr, kCVPixelBufferPixelFormatTypeKey, CFNumberCreate(NULL, kCFNumberSInt32Type, &kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange));
    //CFDictionarySetValue(destPixelBufferAttr, kCVPixelBufferPixelFormatTypeKey, (const void*)kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    //CFDictionarySetBoolean(destPixelBufferAttr, kCVPixelBufferOpenGLESCompatibilityKey, YES); // OpenGL|ES 兼容
    CFDictionarySetValue(destPixelBufferAttr, kCVPixelBufferOpenGLESCompatibilityKey, kCFBooleanTrue); // OpenGL|ES 兼容
    
    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;
    callbackRecord.decompressionOutputRefCon = (__bridge void *)(self);
    
    VTDecompressionSessionRef decodeSession;
    OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                   format,
                                                   nil,
                                                   destPixelBufferAttr,
                                                   &callbackRecord,
                                                   &decodeSession);
    
    CFRelease(destPixelBufferAttr);
    if (status != noErr) {
        NSLog(@"[PIVideoDecode] create decompression failed");
        return nil;
    }
    return decodeSession;
}

- (void)rebuildSession {
    
    [self.lock lock];
    
    if (self.session) {
        NSLog(@"[PIVideoDecode] invalidate session: %p", self.session);
        VTDecompressionSessionInvalidate(self.session);
        self.session = nil;
    }
    
    NSData *sps = [self dataFromHexString:@"274d001e ab40c02a f2da"];
    NSData *pps = [self dataFromHexString:@"28ee3c30"];
    self.vFormatDescription = [self videoFormatDescriptionFromSps:sps pps:pps];
    if (self.vFormatDescription == nil) {
        NSLog(@"[PIVideoDecode] rebuild session failed: vFormatDescription create failed");
        [self.lock unlock];
        return;
    }
    
    self.session = [self decompressionSessionFrom:self.vFormatDescription];
    NSLog(@"[PIVideoDecode] newborn sessoin: %p", self.session);
    
    [self.lock unlock];
}

- (void)decodeData:(NSData *)data completionHandle:(PIVideoDecodeCompletionHandle)completionHandle {
    
    [self.lock lock];
    
    self.vDecodeCompHandle = completionHandle;
    if (self.vFormatDescription == nil) {
        NSLog(@"[PIVideoDecode] decodeData failed: CMVideoFormatDescription is nil");
        if (completionHandle) {
            completionHandle(nil);
        }
        [self.lock unlock];
        return;
    }
    
    uint32_t decodeFlags = 0;
    decodeFlags |= kVTDecodeFrame_EnableAsynchronousDecompression;
    decodeFlags |= kVTDecodeFrame_1xRealTimePlayback;
    
    CMSampleBufferRef sampleBuffer = [self sampleBufferFromVideoFormatDescription:self.vFormatDescription naluData:data];
    
    if (self.session) {
        VTDecompressionSessionDecodeFrame(self.session, sampleBuffer, decodeFlags, nil, 0);
        CFRelease(sampleBuffer);
    } else {
        CFRelease(sampleBuffer);
    }
    [self.lock unlock];
}

- (NSData *)dataFromHexString:(NSString *)string {
    
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    long length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

- (void)didBecomeActive {
    
    //NSLog(@"[PIVideoDecode] didBecomeActive");
}

- (void)willResignActive {
    
    //NSLog(@"[PIVideoDecode] willResignActive");
}

- (void)didEnterBackground {
    
    //NSLog(@"[PIVideoDecode] didEnterBackground");
}

- (void)willEnterForeground {
    
    //NSLog(@"[PIVideoDecode] willEnterForeground");
    [self rebuildSession];
}

- (void)addObservers {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)destroy { // 测试代码，不要调用，解决内存泄漏问题
    
    self.sps = nil;
    self.pps = nil;
    self.spspps = nil;
    self.vFormatDescription = nil;
    VTDecompressionSessionInvalidate(self.session);
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
