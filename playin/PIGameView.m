//
//  PIGameView.m
//  playin
//
//  Created by lijunge on 2019/5/5.
//  Copyright © 2019 A. All rights reserved.
//

#import "PIGameView.h"
#import "PICommon.h"
#import "PIDeviceInfo.h"
@interface PIGameView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *PINIcon;
@property (nonatomic, strong) UIButton *countdownButton;
@property (nonatomic, strong) UIButton *installButton;
@property (nonatomic, strong) UILabel *installLabel;
@property (nonatomic, strong) UILabel *floatLabel;
// 横屏 orientation为 1
@property (nonatomic, assign) NSInteger gameOrientation;
@end

@implementation PIGameView

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
    
    [self addSubview:self.containerView];
   // [self.containerView addSubview:self.PINIcon];
    [self addSubview:self.countdownButton];
    [self addSubview:self.floatLabel];
    //暂时隐藏 installButton
//    [self addSubview:self.installButton];
//    [self.installButton addSubview:self.installLabel];
}

- (void)layout_subviews {
    
    CGFloat gameWidth = self.frame.size.width;
    
    CGFloat countdownBtnWH = 36;
    _countdownButton.frame = CGRectMake(gameWidth - countdownBtnWH - 10, kPIStatusBarHeight, countdownBtnWH, countdownBtnWH);
    _countdownButton.layer.cornerRadius = countdownBtnWH / 2;
    _countdownButton.layer.masksToBounds = YES;
    
    CGFloat fontScale = gameWidth / 375;
    CGFloat labelWidth = 300 * fontScale;
    CGFloat labelHeigth = 30;
    CGFloat topHeight = [PIDeviceInfo isIPhone_X_Series] ? 20 : 3;
    CGFloat labelY = self.frame.size.height - labelHeigth - topHeight;
    CGFloat labelX = self.frame.size.width / 2.0 - labelWidth / 2.0;
    _floatLabel.frame = CGRectMake(labelX, labelY, labelWidth, labelHeigth);
    /*
    CGFloat btnWidth = 120;
    CGFloat btnHeight = 60;
    CGFloat btnX = self.bounds.size.width;
    CGFloat btnY = self.bounds.size.height - btnHeight - 50;
    _installButton.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
    
    _installLabel.frame = _installButton.bounds;
     */
}

- (void)showInstallButtonAnimation {
    
    CGRect installFrame = _installButton.frame;
    if (_gameOrientation == 1) {
        CGAffineTransform trans1 = CGAffineTransformMakeRotation(M_PI/2);
        CGFloat horizontal = [PIDeviceInfo isIPhone_X_Series] ? 80 : 60;
        /*思路：先旋转，再设置（隐藏时的）中心点middlePoint，再设置（出现时的）中心点endPoint*/
        // CGAffineTransformTranslate 默认都是围绕视图的中心点来进行的
        _installButton.transform = CGAffineTransformTranslate(trans1, 0, 0/*横屏竖直方向(话筒-home)*/);
        // 设置第二步的位置
        CGPoint middlePoint = CGPointMake(horizontal + _installButton.frame.size.width / 2, self.frame.size.height + _installButton.frame.size.height / 2);
        _installButton.center = middlePoint;
        [UIView animateWithDuration:0.4 animations:^{
            // 设置第三步的位置
            CGPoint endPoint = CGPointMake(horizontal + self.installButton.frame.size.width / 2, self.frame.size.height - self.installButton.frame.size.height/2);
            self.installButton.center = endPoint;
        }];
        
    } else {
        installFrame.origin.x = installFrame.origin.x - installFrame.size.width;
        [UIView animateWithDuration:0.4 animations:^{
            self.installButton.frame = installFrame;
        }];
    }
}

- (void)finishPlayInGame {
    
    //_installButton.hidden = YES;
   // _floatLabel.hidden = YES;
    _countdownButton.hidden = YES;
}

- (void)gameDurationCountdown:(int)time {
    
    _countdownButton.hidden = NO;
    [_countdownButton setTitle:[NSString stringWithFormat:@"%d", time] forState:UIControlStateNormal];
}

- (void)startPlayInGame {
    
    _countdownButton.hidden = NO;
}

- (void)configGameViewOrientation:(NSInteger)orientation {
    
    _gameOrientation = orientation;
    if (orientation == 1) {
        CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
        CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
        if (screenWidth > screenHeight) {
            //横屏 游戏是横屏 手机横屏
            CGFloat labelHeigth = 30;
            CGFloat labelX = self.frame.size.width / 2.0;
            CGAffineTransform trans1 = CGAffineTransformMakeRotation(M_PI/2);
            _floatLabel.transform = CGAffineTransformTranslate(trans1, -labelX, self.frame.size.height / 2.0 - labelHeigth / 2.0);
            _countdownButton.transform = CGAffineTransformTranslate(trans1, 0, 0);
        } else {
            //竖屏 游戏是横屏 手机是竖屏
            CGFloat labelHeigth = 30;
            CGFloat labelX = self.frame.size.height / 2.0;
            CGAffineTransform trans1 = CGAffineTransformMakeRotation(M_PI/2);
            _floatLabel.transform = CGAffineTransformTranslate(trans1, -labelX, self.frame.size.width / 2.0 - labelHeigth / 2.0);
            //倒计时按钮，旋转90
            _countdownButton.transform = CGAffineTransformTranslate(trans1, 0, 0);
        }
        
    } else {
        _countdownButton.transform = CGAffineTransformMakeRotation(0);
        
    }
}

- (void)installAction {
}

- (UIView *)containerView {
    if (!_containerView) {
        UIView *container = [[UIView alloc] init];
        _containerView = container;
    }
    return _containerView;
}

- (UIImageView *)PINIcon {
    if (!_PINIcon) {
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        imgView.layer.masksToBounds = YES;
        imgView.hidden = YES;
        _PINIcon = imgView;
    }
    return _PINIcon;
}

- (UIButton *)countdownButton {
    if (!_countdownButton) {
        UIButton *button = [[UIButton alloc] init];
        button.userInteractionEnabled = NO;
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        _countdownButton = button;
    }
    return _countdownButton;
}

- (UILabel *)floatLabel {
    if (!_floatLabel) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont fontWithName:@"Baskerville-BoldItalic" size:18];
        label.text = @"PlayIN Ads";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:0.9 alpha:0.9];
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOffset = CGSizeMake(2, 2);
        _floatLabel = label;
    }
    return _floatLabel;
}

- (UIButton *)installButton {
    if (!_installButton) {
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [kPINormalColor colorWithAlphaComponent:0.7];
        [button addTarget:self action:@selector(installAction) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES;
        _installButton = button;
    }
    return _installButton;
}

- (UILabel *)installLabel {
    if (!_installLabel) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"Install";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:24];
        _installLabel = label;
    }
    return _installLabel;
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}
@end
