//
//  PIDeviceInfo.h
//  playin
//
//  Created by A on 2019/3/12.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIDeviceInfo : NSObject
+ (NSString *)idfa;
+ (NSString *)deviceName;
+ (NSDictionary *)allDeviceInfo;
+ (BOOL)isIPhone_X_Series;
+ (BOOL)isIPhone_X;
+ (BOOL)isIPhone_XR;
+ (BOOL)isIPhone_XS_MAX;
+ (BOOL)isIpad;
@end

NS_ASSUME_NONNULL_END
