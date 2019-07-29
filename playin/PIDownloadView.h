//
//  PIDownloadView.h
//  playin
//
//  Created by lijunge on 2019/5/5.
//  Copyright © 2019 A. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    PIDownloadPageTypeContinue,
    PIDownloadPageTypeDownlod
} PIDownloadPageType;

@protocol PIDownloadViewDelegate <NSObject>

- (void)downloadViewCloseButtonTapped;
- (void)downloadViewInstallButtonTapped;
- (void)downloadViewContinueButtonTapped;

@end

@interface PIDownloadView : UIView

@property (nonatomic, weak) id<PIDownloadViewDelegate> delegate;
- (void)showDownloadViewWithPageType:(PIDownloadPageType)pageType
                         orientation:(int)orientation
                        continueText:(NSString *)continueText
                         installText:(NSString *)installText;
- (void)configPlayInOrientationInfo:(int)orientation;
@end

NS_ASSUME_NONNULL_END
