//
//  PlayInView.m
//  playin
//
//  Created by A on 2019/2/26.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PlayInView.h"
#import "PITouchView.h"
#import "PIVideoDisplay.h"
#import "PIGameView.h"
#import "PIDownloadView.h"
#import "PIDeviceInfo.h"
@interface PlayInView () <PITouchViewDelegate,PIDownloadViewDelegate>
@property (nonatomic, strong) PIVideoDisplay *display;
@property (nonatomic, strong) PITouchView *touchView;
@property (nonatomic, strong) PIGameView *gameView;
@property (nonatomic, strong) PIDownloadView *downloadView;
@property (nonatomic, assign) int orientation;    //游戏横竖屏 0 竖屏 1横屏
@property (nonatomic, assign) CGFloat originalW;
@property (nonatomic, assign) CGFloat originalH;
@property (nonatomic, assign) CGRect displayRect;

@end

@implementation PlayInView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = UIColor.blackColor;
        CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
        CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
        if (screenWidth > screenHeight) {
            //横屏
            self.originalW = screenHeight;
            self.originalH = screenWidth;
        } else {
            //竖屏
            self.originalW = screenWidth;
            self.originalH = screenHeight;
        }
        CGFloat scale = 375.0/667.0;
        CGFloat displayX = 0;
        CGFloat displayW = self.originalW;
        CGFloat displayH = displayW / scale;
        if ([PIDeviceInfo isIpad]) {
            //适配ipad
            displayH = self.originalH;
            displayW = scale * displayH;
            displayX = self.originalW / 2.0 - displayW / 2.0;
        }
        CGFloat displayY = self.originalH/2 - displayH/2;
        self.displayRect = CGRectMake(displayX, displayY, displayW, displayH);
        
        self.display = [[PIVideoDisplay alloc] initWithFrame:self.displayRect];
        [self addSubview:self.display];
        
        self.touchView = [[PITouchView alloc] initWithFrame:self.display.frame];
        self.touchView.delegate = self;
        [self addSubview:self.touchView];
        
        [self addSubview:self.gameView];
        [self addSubview:self.downloadView];

        [self deviceOrientationChangeObserver];
        if (screenWidth > screenHeight) {
            //横屏
            [self contentOrientationChange];
        }
    }
    return self;
}

- (void)deviceOrientationChangeObserver {
    
    //UIDeviceOrientationDidChangeNotification 通知 SDK支持四个方向，项目不支持仍然能接收到通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}



- (void)removeOrientationChangeObserver {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarFrameNotification
                                                  object:nil
     ];
}


- (void)statusBarOrientationDidChange:(NSNotification *)noti {
    
    if([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait || [UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown) {
        NSLog(@"UIDeviceOrientationPortrait");
        CGAffineTransform trans1 = CGAffineTransformMakeRotation(0);
        self.display.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.touchView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.gameView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.downloadView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.frame = CGRectMake(0, 0, self.originalW, self.originalH);
        CGRect tmpRect = self.display.frame;
        CGFloat displayX = self.originalW / 2.0 - tmpRect.size.width / 2.0;
        CGFloat displayY = self.originalH / 2.0 - tmpRect.size.height / 2.0;
        //竖屏游戏
        self.display.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        self.touchView.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        self.gameView.frame = CGRectMake(0, 0, self.originalW, self.originalH);
        self.downloadView.frame = CGRectMake(0, 0, self.originalW, self.originalH);
        
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        NSLog(@"UIDeviceOrientationLandscapeLeft");
        //竖屏游戏，在横屏左右时引导用户朝向正常
        //横屏游戏
        CGAffineTransform trans1 = CGAffineTransformMakeRotation(-M_PI/2);
        self.display.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.touchView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.gameView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.downloadView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.frame = CGRectMake(0, 0, self.originalH, self.originalW);
        CGRect tmpRect = self.display.frame;
        CGFloat displayX = self.originalH / 2.0 - tmpRect.size.width / 2.0;
        CGFloat displayY = self.originalW / 2.0 - tmpRect.size.height / 2.0;
        self.display.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        self.touchView.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        
        self.gameView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
        self.downloadView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
        
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        NSLog(@"UIDeviceOrientationLandscapeRight");
        CGAffineTransform trans1;
        if (self.orientation != 1) {
            //竖屏游戏
            trans1 = CGAffineTransformMakeRotation(M_PI/2);
        } else {
            //横屏游戏
            trans1 = CGAffineTransformMakeRotation(-M_PI/2);
        }
        self.display.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.touchView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.gameView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.downloadView.transform = CGAffineTransformTranslate(trans1, 0, 0);
        self.frame = CGRectMake(0, 0, self.originalH, self.originalW);
        CGRect tmpRect = self.display.frame;
        CGFloat displayX = self.originalH / 2.0 - tmpRect.size.width / 2.0;
        CGFloat displayY = self.originalW / 2.0 - tmpRect.size.height / 2.0;
        self.display.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        self.touchView.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
        self.gameView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
        self.downloadView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
    }
}

- (void)contentOrientationChange {
    
    CGAffineTransform trans1 = CGAffineTransformMakeRotation(-M_PI/2);
    self.display.transform = CGAffineTransformTranslate(trans1, 0, 0);
    self.touchView.transform = CGAffineTransformTranslate(trans1, 0, 0);
    self.gameView.transform = CGAffineTransformTranslate(trans1, 0, 0);
    self.downloadView.transform = CGAffineTransformTranslate(trans1, 0, 0);
    CGRect tmpRect = self.display.frame;
    CGFloat displayX = self.frame.size.width / 2.0 - tmpRect.size.width / 2.0;
    CGFloat displayY = self.frame.size.height / 2.0 - tmpRect.size.height / 2.0;
    self.display.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
    self.touchView.frame = CGRectMake(displayX, displayY, tmpRect.size.width, tmpRect.size.height);
    self.gameView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
    self.downloadView.frame = CGRectMake(0, 0, self.originalH, self.originalW);
}

- (void)displayLastPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    CVPixelBufferRetain(pixelBuffer);
    [self.display displayLastPixelImageBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    CVPixelBufferRetain(pixelBuffer);
    [self.display displayPixelBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
}

- (void)onPITouchViewTouched:(NSData *)data {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInViewTouch:)]) {
        [self.delegate onPlayInViewTouch:data];
    }
}

- (void)configPlayInOrientation:(int)orientation {
    
    self.orientation = orientation;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gameView configGameViewOrientation:orientation];
    });
}

- (void)updateCounter:(int)count {
    
    self.gameView.hidden = NO;
    [self.gameView gameDurationCountdown:count];
}

- (void)updateStatusWithPlayTimes:(int)playTimes
                        playCount:(int)playCount
                     continueText:(NSString *)countinuText
                      installText:(NSString *)installText {
    
    [self.gameView finishPlayInGame];
    self.gameView.hidden = YES;
    self.downloadView.hidden = NO;
    if (playTimes == 1) {
        // show download page
        [self.downloadView showDownloadViewWithPageType:PIDownloadPageTypeDownlod
                                            orientation:self.orientation
                                           continueText:countinuText
                                            installText:installText];
    } else {
        if (playCount == 1) { // continue page
            [self.downloadView showDownloadViewWithPageType:PIDownloadPageTypeContinue
                                                orientation:self.orientation
                                               continueText:countinuText
                                                installText:installText];
        }
        if (playCount == 2) { // download page
            [self.downloadView showDownloadViewWithPageType:PIDownloadPageTypeDownlod
                                                orientation:self.orientation
                                               continueText:countinuText
                                                installText:installText];
        }
    }
}

#pragma mark - PIDownloadView delegate

- (void)downloadViewCloseButtonTapped {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInViewCloseAction)]) {
        [self.delegate onPlayInViewCloseAction];
    }
}

- (void)downloadViewInstallButtonTapped {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInViewInstallAction)]) {
        [self.delegate onPlayInViewInstallAction];
    }
}

- (void)downloadViewContinueButtonTapped {
    
    self.downloadView.hidden = YES;
    self.gameView.hidden = NO;
    [self.gameView startPlayInGame];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInViewContinueAction)]) {
        [self.delegate onPlayInViewContinueAction];
    }
}

- (PIGameView *)gameView {
    if (!_gameView) {
        PIGameView *gameView = [[PIGameView alloc] initWithFrame:self.bounds];
        gameView.userInteractionEnabled = NO;
        _gameView = gameView;
    }
    return _gameView;
}

- (PIDownloadView *)downloadView {
    if (!_downloadView) {
        PIDownloadView *downloadView = [[PIDownloadView alloc] initWithFrame:self.bounds];
        downloadView.hidden = YES;
        downloadView.userInteractionEnabled = YES;
        downloadView.delegate = self;
        _downloadView = downloadView;
    }
    return _downloadView;
}

- (void)removeSubViews {
    
    [self.gameView removeFromSuperview];
    self.gameView = nil;
    [self.downloadView removeFromSuperview];
    self.downloadView = nil;
}

- (void)destroy { // 测试代码，不要调用，解决内存泄漏问题
    
    [self.touchView removeFromSuperview];
    self.touchView = nil;
    [self.display removeFromSuperview];
    self.display = nil;
}

- (void)dealloc {
    
    [self removeOrientationChangeObserver];
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}

@end
