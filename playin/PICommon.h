//
//  PICommon.h
//  playin
//
//  Created by A on 2019/3/7.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIDeviceInfo.h"

extern NSString * const PlayInVersion; // PlayIN SDK version

//------------------------ Color ------------------------
//normal blueColor @"#6699FF"
#define kPINormalColor  ([UIColor colorWithRed:102.0 / 255.0 green:153.0 / 255.0 blue:255.0 / 255.0 alpha:1.0])
//------------------------ Size ------------------------

#define kPIStatusBarHeight ([PIDeviceInfo isIPhone_X_Series] ? 44.0 : 20.0)
#define kPIBottomMargin ([PIDeviceInfo isIPhone_X_Series] ? 34.0 : 0.0)
#define kPINavBarHeight (kPIStatusBarHeight + 44.0)
#define kPITabBarHeight (kPIBottomMargin + 49.0)

#define kPIScreenHeight [UIScreen mainScreen].bounds.size.height
#define kPIScreenWidth [UIScreen mainScreen].bounds.size.width
#define kPIScreenWidthScale (kPIScreenWidth/375.0)

#if !DEBUG
#define NSLog(...)
#endif

#if !DEBUG
#undef assert
#define assert(e) ((void)0)
#endif
