//
//  PIAuth.m
//  playin
//
//  Created by A on 2019/5/9.
//  Copyright © 2019年 lijunge. All rights reserved.
//

#import "PIAuth.h"
#import "PIHttpManager.h"
#import "PIUtil.h"

@implementation PIAuth

+ (void)authWithHost:(NSString *)host key:(NSString *)key success:(PIAuthSuccess)success failure:(PIAuthFailure)failure {

    if (![PIUtil validStr:host]) {
        NSLog(@"[PlayIn] auth error: invalid host");
        return;
    }
    
    if (![PIUtil validStr:key]) {
        NSLog(@"[PlayIn] auth error: invalid sdk_key");
        return;
    }

    NSString *urlStr = [NSString stringWithFormat:@"%@/user/auth", host];
    NSMutableDictionary *authParams = [NSMutableDictionary new];
    [authParams setValue:key forKey:@"sdk_key"];
    
    [PIHttpManager post:urlStr params:authParams success:^(NSDictionary * _Nonnull result) {
        //NSLog(@"PlayIn post result: %@", result);
        id code = [result valueForKey:@"code"];
        if (![PIUtil validObj:code]) {
            if (failure) {
                failure(@"");
            }
            return;
        }
        
        int code_value = [code intValue];
        if (code_value == 0) {
            NSString *sid = [[result valueForKey:@"data"] valueForKey:@"session_key"];
            if (![PIUtil validStr:sid]) {
                NSLog(@"[PlayIn] auth error: session_key invalid");
                return;
            }
            if (success) {
                success(sid);
            }
        } else {
            NSString *errStr = [result valueForKey:@"error"];
            NSLog(@"[PlayIn] start failure: %@", errStr);
            if (failure) {
                failure(errStr);
            }
        }
    } failure:^(NSDictionary * _Nonnull error) {
        NSLog(@"[PlayIn] auth error: %@", error);
    }];
}

@end
