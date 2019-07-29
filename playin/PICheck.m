//
//  PICheck.m
//  playin
//
//  Created by lijunge on 2019/5/8.
//  Copyright © 2019 A. All rights reserved.
//

#import "PICheck.h"
#import "PIHttpManager.h"
#import "PIUtil.h"
#import "PIConfigure.h"
#import "PIDeviceInfo.h"
#import "PICommon.h"

@implementation PICheck

+ (void)checkAvaliableWithHost:(NSString *)host
                          adid:(NSString *)adid
                    sessionKey:(NSString *)sessionKey
                         pings:(NSDictionary *)pings
                      callback:(void(^)(BOOL result))avaliable {
    
    if (![PIUtil validStr:adid]) {
        NSLog(@"[PICheck] check avaliable error: adid is invalid");
        [self handleResult:NO callback:avaliable];
        return;
    }
    
    if (![PIUtil validStr:sessionKey]) {
        NSLog(@"[PICheck] check avaliable error: sessionKey is invalid");
        [self handleResult:NO callback:avaliable];
        return;
    }
    
    if (![PIUtil validStr:host]) {
        NSLog(@"[PICheck] check avaliable error: host is invalid");
        [self handleResult:NO callback:avaliable];
        return;
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/user/available", host];
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:sessionKey forKey:@"session_key"];
    [params setValue:adid forKey:@"ad_id"];
    [params setValue:pings forKey:@"pings"];
    [params setValue:[NSNumber numberWithInt:1] forKey:@"os_type"];
    [params setValue:PlayInVersion forKey:@"sdk_version"];
    [params setValue:[PIDeviceInfo allDeviceInfo] forKey:@"device_info"];
    //NSLog(@"[PICheck] params: %@", params);
    [PIHttpManager post:urlStr params:params success:^(NSDictionary * _Nonnull result) {
        NSLog(@"[PICheck] check avaliable result: %@", result);
        dispatch_async(dispatch_get_main_queue(), ^{
            id code = [result valueForKey:@"code"];
            if (![PIUtil validObj:code]) {
                [self handleResult:NO callback:avaliable];
                return;
            }
            int code_value = [code intValue];
            if (code_value == 0) {
                [self handleResult:YES callback:avaliable];
            } else {
                [self handleResult:NO callback:avaliable];
            }
        });
    } failure:^(NSDictionary * _Nonnull error) {
        NSLog(@"[PICheck] check avaliable error: %@", error);
        [self handleResult:NO callback:avaliable];
    }];
}

+ (void)handleResult:(BOOL)result callback:(void(^)(BOOL result))avaliable {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (avaliable) {
            avaliable(result);
        }
    });
}

@end
