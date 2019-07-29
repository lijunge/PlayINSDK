//
//  PlayInView.h
//  playin
//
//  Created by A on 2019/2/26.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PlayInViewDelegate <NSObject>

- (void)onPlayInViewTouch:(NSData *)touchData;
- (void)onPlayInViewInstallAction;
- (void)onPlayInViewContinueAction;
- (void)onPlayInViewCloseAction;

@end

@interface PlayInView : UIView

@property (nonatomic, weak) id<PlayInViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *resultDic;

- (void)displayLastPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)updateCounter:(int)count;
- (void)configPlayInOrientation:(int)orientation;
- (void)updateStatusWithPlayTimes:(int)playTimes
                        playCount:(int)playCount
                     continueText:(NSString *)countinuText
                      installText:(NSString *)installText;
- (void)removeSubViews;

@end

NS_ASSUME_NONNULL_END
