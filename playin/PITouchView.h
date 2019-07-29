//
//  PITouchView.h
//  CloudGame
//
//  Created by A on 2019/1/21.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PITouchViewDelegate <NSObject>

- (void)onPITouchViewTouched:(NSData *)data;

@end

@interface PITouchView : UIView
@property (nonatomic, weak) id<PITouchViewDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame;
@end

NS_ASSUME_NONNULL_END
