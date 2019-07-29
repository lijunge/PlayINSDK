//
//  PIDownloadView.m
//  playin
//
//  Created by lijunge on 2019/5/5.
//  Copyright © 2019 A. All rights reserved.
//

#import "PIDownloadView.h"
#import "PICommon.h"
#import "PIImageInfo.h"
#import "PIReport.h"
#import "PIUtil.h"


@interface PIDownloadView()

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *centerContainer;
@property (nonatomic, strong) UIButton *installButton;
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, assign) CGFloat screenWidthScale;
@property (nonatomic, assign) CGFloat centerContainerWH;

@end

@implementation PIDownloadView

- (instancetype)initWithFrame:(CGRect)frame {
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGRect gameRect;
    if (screenWidth > screenHeight) {
        //横屏
        gameRect = CGRectMake(0, 0, screenHeight, screenWidth);
    } else {
        //竖屏
        gameRect = CGRectMake(0, 0, screenWidth, screenHeight);
    }
    self = [super initWithFrame:gameRect];
    if (self) {
        [self configSubviews];
    }
    return self;
}

- (void)configSubviews {
    
    [self add_subviews];
    [self layout_subviews];
}

- (void)add_subviews {
    
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.closeButton];
    [self addSubview:self.centerContainer];
    [self.centerContainer addSubview:self.installButton];
    [self.centerContainer addSubview:self.continueButton];
}

- (void)layout_subviews {
    
    CGFloat downloadWidth = self.frame.size.width;
    CGFloat downloadHeight = self.frame.size.height;
    
    CGFloat closeBtnWH = 36;
    _closeButton.frame = CGRectMake(downloadWidth - closeBtnWH - 10, kPIStatusBarHeight, closeBtnWH, closeBtnWH);
    _closeButton.layer.cornerRadius = closeBtnWH / 2;
    _closeButton.layer.masksToBounds = YES;
    
    self.screenWidthScale = downloadWidth / 375.0;
    self.centerContainerWH = 220*self.screenWidthScale;
    CGPoint containerCenter = CGPointMake(downloadWidth/2, downloadHeight/2);
    _centerContainer.frame = CGRectMake(0, 0, self.centerContainerWH, 190);
    _centerContainer.center = containerCenter;
    
    CGFloat btnWidth = 160 * self.screenWidthScale;
    CGFloat btnHeigth = 60;
    CGFloat btnY = 10;
    CGFloat btnX = (self.centerContainerWH - btnWidth)/2;
    
    _installButton.frame = CGRectMake(btnX, btnY, btnWidth, btnHeigth);
    _installButton.layer.cornerRadius = btnHeigth/2;
    _installButton.layer.masksToBounds = YES;
    
    _continueButton.frame = CGRectMake(btnX, btnY + btnHeigth + 50, btnWidth, btnHeigth);
    _continueButton.layer.cornerRadius = btnHeigth/2;
    _continueButton.layer.masksToBounds = YES;
    
}

- (void)showDownloadViewWithPageType:(PIDownloadPageType)pageType
                         orientation:(int)orientation
                        continueText:(NSString *)continueText
                         installText:(NSString *)installText {
    
    if (![PIUtil validStr:installText]) {
        installText = @"Install";
    }
    if (![PIUtil validStr:continueText]) {
        continueText = @"Continue";
    }
    [self configPlayInOrientationInfo:orientation];
    [self configPageTextInfoWithContinue:continueText install:installText pageInfo:pageType];
    
}

- (void)configPlayInOrientationInfo:(int)orientation {
    
    self.centerContainer.hidden = NO;
    self.centerContainer.alpha = 0.1;
    [UIView animateWithDuration:0.8 animations:^{
        self.centerContainer.alpha = 1.0;
    }];
    if (orientation == 1) {
        CGAffineTransform trans1 = CGAffineTransformMakeRotation(M_PI/2);
        // 安装按钮旋转
        self.centerContainer.transform = CGAffineTransformTranslate(trans1, 0, 0);
    }
}

- (void)configPageTextInfoWithContinue:(NSString *)continueString
                               install:(NSString *)installString
                              pageInfo:(PIDownloadPageType)pageType{
    
    CGFloat actualWidth = 160 * self.screenWidthScale;
    CGRect textRect = [installString boundingRectWithSize:CGSizeMake(self.frame.size.width, 60) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:20]} context:nil];
    CGFloat textWidth = textRect.size.width;
    if (textWidth < actualWidth) {
        actualWidth = actualWidth + 20;
    } else {
        actualWidth = textWidth + 20;
    }
    CGFloat btnHeigth = 60;
    CGFloat btnY = 10;
    CGFloat btnX = (self.centerContainerWH - actualWidth)/2;
    self.installButton.frame = CGRectMake(btnX, btnY, actualWidth, btnHeigth);
    btnY = btnY + btnHeigth + 50;
    self.continueButton.frame = CGRectMake(btnX, btnY, actualWidth, btnHeigth);
    [self.installButton setTitle:installString forState:UIControlStateNormal];
    [self.continueButton setTitle:continueString forState:UIControlStateNormal];
    
    if (pageType == PIDownloadPageTypeContinue) {
        //continue page
        self.continueButton.hidden = NO;
    } else {
        //download page
        self.continueButton.hidden = YES;
        // 安装按钮居中
        self.installButton.center = CGPointMake(self.centerContainerWH/2, 190/2);
    }
}

- (void)closeAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadViewCloseButtonTapped)]) {
        [self.delegate downloadViewCloseButtonTapped];
    }
}

- (void)installAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadViewInstallButtonTapped)]) {
        [self.delegate downloadViewInstallButtonTapped];
    }
}

- (void)continueAction {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadViewContinueButtonTapped)]) {
        [self.delegate downloadViewContinueButtonTapped];
    }
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[PIImageInfo PlayInCancelImage] forState:UIControlStateNormal];
        button.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [button addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        _closeButton = button;
    }
    return _closeButton;
}

- (UIView *)centerContainer {
    if (!_centerContainer) {
        UIView *container = [[UIView alloc] init];
        _centerContainer = container;
    }
    return _centerContainer;
}

- (UIButton *)installButton {
    if (!_installButton) {
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [kPINormalColor colorWithAlphaComponent:0.7];
        [button setTitle:@"Install" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(installAction) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _installButton = button;
    }
    return _installButton;
}

- (UIButton *)continueButton {
    if (!_continueButton) {
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [kPINormalColor colorWithAlphaComponent:0.7];
        [button setTitle:@"Continue" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(continueAction) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        
        _continueButton = button;
    }
    return _continueButton;
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}

@end
