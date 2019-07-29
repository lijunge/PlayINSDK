//
//  PIPlay.m
//  playin
//
//  Created by A on 2019/5/9.
//  Copyright © 2019年 lijunge. All rights reserved.
//

#import "PIPlay.h"
#import "PIUtil.h"
#import "net/PIStream.h"
#import "PIVideoDecode.h"
#import "PlayInView.h"
#import "PIDeviceInfo.h"

@interface PIPlay () <PIStreamDelegate, PlayInViewDelegate>
@property (nonatomic, strong) PIStream *sockManager;
@property (nonatomic, weak) PIVideoDecode *vDecode;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) int orientation;
@property (nonatomic, strong) NSMutableDictionary *playDic;
@property (nonatomic, copy) PIPlaySuccess success;
@property (nonatomic, copy) PIPlayFailure failure;
@property (nonatomic, strong) NSString *continueText;
@property (nonatomic, strong) NSString *installText;
@property (nonatomic, strong) NSData *pixelData;
@end

@implementation PIPlay

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super init]) {
        self.frame = frame;
        self.vDecode = PIVideoDecode.shared;
        self.sockManager = [PIStream new];
        self.sockManager.delegate = self;
        [self setupPlayInView];
    }
    return self;
}

- (void)startWithHost:(NSString *)host
                 port:(uint16_t)port
                token:(NSString *)token
             duration:(int)duration
          orientation:(int)orientation
         continueText:(NSString *)continueText
          installText:(NSString *)installText
              failure:(PIPlayFailure)failure {
    
    if (![PIUtil validStr:host] ||
        ![PIUtil validStr:token]) {
        if (failure) {
            failure(@"[PIPlay] invalid params host or token");
        }
        return;
    }
    self.continueText = continueText;
    self.installText = installText;
    self.orientation = orientation;
    [self.sockManager startStreamWithToken:token
                          deviceName:[PIDeviceInfo deviceName]
                                host:host
                                port:port
                            duration:duration];
}

- (void)setupPlayInView {
    
    self.playInView = [[PlayInView alloc] initWithFrame:self.frame];
    self.playInView.hidden = YES;
    self.playInView.delegate = self;
}

- (void)stop {
    
    NSLog(@"[PIPlay] stop");
    [self.sockManager stopStream];
    self.sockManager = nil;
    
    [self stopVideo];
}

- (void)stopVideo {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playInView removeSubViews];
        [self.playInView removeFromSuperview];
    });
}

- (void)countdown:(int)count {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playInView updateCounter:count];
    });
}

- (void)updateCurrentPlayTimes:(int)cTimes totalPlayTimes:(int)tTimes {
    
    [self updateDownloadViewWithPlayTimes:tTimes playCount:cTimes];
    if (cTimes == tTimes) {
        [self decodeLastSlice:self.pixelData];
    }
}

- (void)updateDownloadViewWithPlayTimes:(int)times playCount:(int)count {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playInView updateStatusWithPlayTimes:times
                                         playCount:count
                                      continueText:self.continueText
                                       installText:self.installText];
    });
}

#pragma mark - PISocketManagerDelegate
- (void)onPIStreamEnded:(NSError* )error {
    
    [self updateDownloadViewWithPlayTimes:1 playCount:1];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlaySocketEnd)]) {
        [self.delegate onPIPlaySocketEnd];
    }
}

- (void)onPIStreamReceivedVideoData:(NSData *)data {
   
    // see H.264-AVC-ISO_IEC_14496-10-2012.pdf
    // Table 7-1 – NAL unit type codes, syntax element categories, and NAL unit type classes
    uint8_t *ptr = (uint8_t *)data.bytes;
    uint8_t nalu_type = ptr[4] & 0x1F; // 前四字节是NALU长度码
    //NSLog(@"nalu_type: %u", nalu_type);

    if (nalu_type == 1) { // Coded slice of a non-IDR picture
        [self decodeSlice:data];
    } else if (nalu_type == 5) { // Coded slice of an IDR picture
        [self decodeSlice:data];
        self.pixelData = data;
    } else if (nalu_type == 6) { // Supplemental enhancement information (SEI)
    } else if (nalu_type == 7) { // Sequence parameter set
       // [self synthesizeAndUpdateParameterSet:data];
    } else if (nalu_type == 8) { // Picture parameter set
       // [self synthesizeAndUpdateParameterSet:data];
    }
}

//// socket理论上在试玩期间内不能断开,会重连,所以该次重连基本会是主动stopPlay
//- (void)onPISocketManagerDisConnected {
//
//}

- (void)onPIStreamRegisterFailure:(NSString *)error {
    
    NSLog(@"[PIPlay] register stream server error: %@", error);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlayError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onPIPlayError:error];
        });
    }
}

- (void)onPIStreamRegisterSuccess:(NSDictionary *)result {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playInView.hidden = NO;
        [self.playInView configPlayInOrientation:self.orientation];
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlayStarted)]) {
            [self.delegate onPIPlayStarted];
        }
    });
}

- (void)synthesizeAndUpdateParameterSet:(NSData *)xps {

    uint8_t *ptr = (uint8_t *)xps.bytes;
    uint8_t nalu_type = ptr[4] & 0x1F; // 前四字节是NALU长度码

    if (nalu_type == 7) { // sps
        
        NSData *tmpData = [xps subdataWithRange:NSMakeRange(3, 1)];
        Byte *byte = (Byte *)[tmpData bytes];
        int spsLength = (byte[3] << 24) + (byte[2] << 16) + (byte[1] << 8) + (byte[0]); //大端
        
        NSData *spsData = [xps subdataWithRange:NSMakeRange(4, spsLength)];
        NSData *ppsData = [xps subdataWithRange:NSMakeRange(spsLength + 8, [xps length] - spsLength - 8)];
        NSLog(@"tmpData%@-%@-%@",tmpData,spsData,ppsData);
        [self.vDecode updateSps:spsData pps:ppsData];
    } else if (nalu_type == 8) { // pps
//        OS_UNUSED NSData *pps = [xps subdataWithRange:NSMakeRange(4, [xps length] - 4)];
//        NSLog(@"PlayIn pps: %@ sps: %@", pps, tmpSps);
        //
    }
}


- (void)decodeSlice:(NSData *)slice {
    
    __weak typeof(self) weakSelf = self;
    [self.vDecode decodeData:slice completionHandle:^(CVImageBufferRef imageBuffer) {
        if (imageBuffer == nil) { return; }
        CVPixelBufferRetain(imageBuffer);
        [((PlayInView*)weakSelf.playInView) displayPixelBuffer:imageBuffer];
        CVPixelBufferRelease(imageBuffer);
    }];
}

- (void)decodeLastSlice:(NSData *)slice {
    
    __weak typeof(self) weakSelf = self;
    [self.vDecode decodeData:slice completionHandle:^(CVImageBufferRef imageBuffer) {
        if (imageBuffer == nil) { return; }
        CVPixelBufferRetain(imageBuffer);
        [((PlayInView*)weakSelf.playInView) displayLastPixelBuffer:imageBuffer];
        CVPixelBufferRelease(imageBuffer);
    }];
}

#pragma mark - PlayInView delegate

- (void)onPlayInViewTouch:(NSData *)touchData {
    
    [self.sockManager sendTouchData:touchData];
}

- (void)onPlayInViewInstallAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlayInstall)]) {
        [self.delegate onPIPlayInstall];
    }
}

- (void)onPlayInViewContinueAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlayContinue)]) {
        [self.delegate onPIPlayContinue];
    }
}

- (void)onPlayInViewCloseAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPIPlayClosed)]) {
        [self.delegate onPIPlayClosed];
    }
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}


@end
