//
//  PIVideoDisplay.m
//  playin
//
//  Created by A on 2017/10/19.
//  Copyright © 2017年 A. All rights reserved.
//

#import "PIVideoDisplay.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

//http://blog.csdn.net/fernandowei/article/details/52179631

@interface PIVideoDisplay()
@property(nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property(atomic, assign) CVPixelBufferRef pixelBuffer;
@property(nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) UIImageView *pixelImgView;
@end

CMFormatDescriptionRef CreateFormatDescriptionFromCodecData(UInt32 format_id, int width, int height, const uint8_t *extradata, int extradata_size, uint32_t atom);

@implementation PIVideoDisplay

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.displayLayer = [AVSampleBufferDisplayLayer new];
        self.displayLayer.frame = frame;
        self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.displayLayer.opaque = YES;
        self.backgroundColor = [UIColor colorWithRed:131/255.0 green:175/255.0 blue:155/255.0 alpha:1];
        [self.layer addSublayer:self.displayLayer];
        [self addObservers];
        // self.lock = [NSLock new];
    }
    return self;
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    //    CMTimebaseRef timebase = nil;
    //    CMTimebaseCreateWithMasterClock(kCFAllocatorDefault, CMClockGetHostTimeClock(), &timebase);
    //    CMTimebaseSetTime(timebase, CMTimeMake(5, 1));
    //    CMTimebaseSetRate(timebase, 1.0);
    //    [self.displayLayer setControlTimebase:timebase];
    
    {
    //    int width = 376;
    //    int height = 668;// 014d001e ffe1000a 274d001e ab40c02a f2da0100 0428ee3c 30
    ////    int width = 750;
    ////    int height = 1334;
    //    NSData *exdata = [self dataFromHexString:@"014d001e ffe1000a 274d001e ab40c02a f2da0100 0428ee3c 30"];
    //    CMFormatDescriptionRef fmt = CreateFormatDescriptionFromCodecData(kCMVideoCodecType_H264, width, height, [exdata bytes], (int)[exdata length], IJK_VTB_FCC_AVCC);
    //
    //    //NSLog(@"fmt: %@", fmt);
    //    CFRelease(fmt);
    }
    
    [self.lock lock];
    
    //不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    if (result != 0 || videoInfo == NULL) {
        NSLog(@"[PIVideoDisplay] displayPixelBuffer err: CMVideoFormatDescriptionCreateForImageBuffer failed");
        [self.lock unlock];
        return;
    }
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    if (result != 0 || sampleBuffer == NULL) {
        NSLog(@"[PIVideoDisplay] displayPixelBuffer err: CMSampleBufferCreateForImageBuffer failed");
        [self.lock unlock];
        return;
    }
   
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
    CFRelease(videoInfo);
    [self.lock unlock];
}

- (void)rebuildSampleBufferDisplayLayer {
    
    NSLog(@"[PIVideoDisplay] rebuildSampleBufferDisplayLayer");
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}

- (void)teardownSampleBufferDisplayLayer {
    
    if (self.displayLayer){
        [self.displayLayer stopRequestingMediaData];
        [self.displayLayer removeFromSuperlayer];
        self.displayLayer = nil;
    }
}

- (void)setupSampleBufferDisplayLayer {
    
    if (!self.displayLayer){
        self.displayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.displayLayer.frame = self.bounds;
        self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.displayLayer.opaque = YES;
        [self.layer addSublayer:self.displayLayer];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.displayLayer.frame = self.bounds;
        self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [CATransaction commit];
    }
}

void dict_set_string(CFMutableDictionaryRef dict, CFStringRef key, const char * value)
{
    CFStringRef string;
    string = CFStringCreateWithCString(NULL, value, kCFStringEncodingASCII);
    CFDictionarySetValue(dict, key, string);
    CFRelease(string);
}

void dict_set_boolean(CFMutableDictionaryRef dict, CFStringRef key, BOOL value)
{
    CFDictionarySetValue(dict, key, value ? kCFBooleanTrue: kCFBooleanFalse);
}

void dict_set_object(CFMutableDictionaryRef dict, CFStringRef key, CFTypeRef *value)
{
    CFDictionarySetValue(dict, key, value);
}

void dict_set_data(CFMutableDictionaryRef dict, CFStringRef key, uint8_t * value, uint64_t length)
{
    CFDataRef data;
    data = CFDataCreate(NULL, value, (CFIndex)length);
    CFDictionarySetValue(dict, key, data);
    CFRelease(data);
}

void dict_set_i32(CFMutableDictionaryRef dict, CFStringRef key, int32_t value)
{
    CFNumberRef number;
    number = CFNumberCreate(NULL, kCFNumberSInt32Type, &value);
    CFDictionarySetValue(dict, key, number);
    CFRelease(number);
}

CMFormatDescriptionRef CreateFormatDescriptionFromCodecData(UInt32 format_id, int width, int height, const uint8_t *extradata, int extradata_size, uint32_t atom)
{
    CMFormatDescriptionRef fmt_desc = NULL;
    OSStatus status;
    
    CFMutableDictionaryRef par = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef atoms = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef extensions = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    /* CVPixelAspectRatio dict */
    dict_set_i32(par, CFSTR ("HorizontalSpacing"), 0);
    dict_set_i32(par, CFSTR ("VerticalSpacing"), 0);
    /* SampleDescriptionExtensionAtoms dict */
    dict_set_data(atoms, CFSTR ("avcC"), (uint8_t *)extradata, extradata_size);
    
    /* Extensions dict */
    dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationBottomField"), "left");
    dict_set_string(extensions, CFSTR ("CVImageBufferChromaLocationTopField"), "left");
    dict_set_boolean(extensions, CFSTR("FullRangeVideo"), FALSE);
    dict_set_object(extensions, CFSTR ("CVPixelAspectRatio"), (CFTypeRef *) par);
    dict_set_object(extensions, CFSTR ("SampleDescriptionExtensionAtoms"), (CFTypeRef *) atoms);
    status = CMVideoFormatDescriptionCreate(NULL, format_id, width, height, extensions, &fmt_desc);
    
    CFRelease(extensions);
    CFRelease(atoms);
    CFRelease(par);
    
    if (status == 0)
        return fmt_desc;
    else
        return NULL;
}

CMSampleBufferRef CreateSampleBufferFrom(CMFormatDescriptionRef fmt_desc, void *demux_buff, size_t demux_size)
{
    OSStatus status;
    CMBlockBufferRef newBBufOut = NULL;
    CMSampleBufferRef sBufOut = NULL;
    
    status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                demux_buff,
                                                demux_size,
                                                kCFAllocatorNull,
                                                NULL,
                                                0,
                                                demux_size,
                                                FALSE,
                                                &newBBufOut);
    
    if (!status) {
        status = CMSampleBufferCreate(NULL,
                                      newBBufOut,
                                      TRUE,
                                      0,
                                      0,
                                      fmt_desc,
                                      1,
                                      0,
                                      NULL,
                                      0,
                                      NULL,
                                      &sBufOut);
    }
    
    CFRelease(newBBufOut);
    if (status == 0) {
        return sBufOut;
    } else {
        return NULL;
    }
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

- (void)displayLastPixelImageBuffer:(CVImageBufferRef)imageBuffer {
    
    UIImage *image = [self imageWithImageBuffer:imageBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.pixelImgView = [[UIImageView alloc] initWithImage:image];
        self.pixelImgView.hidden = NO;
        [self addSubview:self.pixelImgView];
    });
}

- (UIImage *)imageWithImageBuffer:(CVImageBufferRef)imageBuffer {
    
    [self.lock lock];
    UIImage *uiImage = nil;
    if (@available(iOS 9.0, *)) {
        CVPixelBufferRetain(imageBuffer);
        CGImageRef cgImage = nil;
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, nil, &cgImage);
        uiImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CVPixelBufferRelease(imageBuffer);
    } else {
        CVPixelBufferRetain(imageBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGRect imageRect = CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
        CGImageRef cgImage = [temporaryContext createCGImage:ciImage fromRect:imageRect];
        uiImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CVPixelBufferRelease(imageBuffer);
    }
    [self.lock unlock];
    return uiImage;
}

- (void)didBecomeActive {
    
    //NSLog(@"[PIVideoDisplay] didBecomeActive");
}

- (void)willResignActive {
    
    //self.pixelImgView.hidden = NO;
    //[self setupBackgroundImage]; // TODO: crash
    //NSLog(@"[PIVideoDisplay] willResignActive");
}

- (void)didEnterBackground {
    
    //NSLog(@"[PIVideoDisplay] didEnterBackground");
}

- (void)willEnterForeground {
    
   // NSLog(@"[PIVideoDisplay] willEnterForeground");
    [self rebuildSampleBufferDisplayLayer];
    
}

- (void)addObservers {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
