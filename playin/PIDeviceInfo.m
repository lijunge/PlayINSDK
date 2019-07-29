//
//  PIDeviceInfo.m
//  playin
//
//  Created by A on 2019/3/12.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PIDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
@implementation PIDeviceInfo

+ (NSString *)deviceName {
    
    return [[UIDevice currentDevice] name];
}

+ (NSString *)idfa {
    
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

+ (NSString *)osVersion {
    
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    return osVer;
}

+ (BOOL)isIPhone_X_Series
{
    static BOOL is_X_Series = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        is_X_Series = ([self isIPhone_X] || [self isIPhone_XR] || [self isIPhone_XS_MAX]);
    });
    return is_X_Series;
}

+ (BOOL)isIPhone_X
{
    static BOOL is_X_ = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *iPhone_X_Models = @[@"iPhone10,3",
                                     @"iPhone10,6"];
        NSArray *iPhone_XS_Models = @[@"iPhone11,2"];
        NSString *currentModel = [self deviceModel];
        is_X_ = ([iPhone_X_Models containsObject:currentModel] || [iPhone_XS_Models containsObject:currentModel]);
    });
    return is_X_;
    
    
}

+ (BOOL)isIPhone_XR
{
    static BOOL is_XR = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *iPhone_XR_Models = @[@"iPhone11,8"];
        NSString *currentModel = [self deviceModel];
        is_XR = [iPhone_XR_Models containsObject:currentModel];
    });
    return is_XR;
}

+ (BOOL)isIPhone_XS_MAX
{
    static BOOL is_XS_MAX = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *iPhone_XS_MAX_Models = @[@"iPhone11,6",@"iPhone11,4"];
        NSString *currentModel = [self deviceModel];
        is_XS_MAX =  [iPhone_XS_MAX_Models containsObject:currentModel];
    });
    return is_XS_MAX;
}

+ (NSString *)deviceModel
{
#if TARGET_IPHONE_SIMULATOR
    // 获取模拟器所对应的 device model
    NSString *model = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
#else
    // 获取真机设备的 device model
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
#endif
    return model;
}

+ (NSDictionary *)allDeviceInfo {
    
    NSMutableDictionary *deviceInfo = [NSMutableDictionary new];
    deviceInfo[@"model"] = [self deviceModel];
    deviceInfo[@"name"] = [self deviceName];
    deviceInfo[@"idfa"] = [self idfa];
    deviceInfo[@"os_version"] = [self osVersion];
    return deviceInfo;
}

+ (BOOL)isIpad {
    
    NSString *deviceType = [UIDevice currentDevice].model;
    if ([deviceType isEqualToString:@"iPad"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
