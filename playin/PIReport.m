//
//  PIReport.m
//  playin
//
//  Created by lijunge on 2019/5/6.
//  Copyright © 2019 A. All rights reserved.
//

#import "PIReport.h"
#import "PIUtil.h"
#import "PIHttpManager.h"

@implementation PIReport

+ (void)reportPlayEndWithHost:(NSString *)host token:(NSString *)token sessionKey:(NSString *)sessionKey {
    
    [self reportWithHost:host action:@"endplay" token:token sessionKey:sessionKey];
}

+ (void)reportAppStoreWithHost:(NSString *)host token:(NSString *)token sessionKey:(NSString *)sessionKey {
    
    [self reportWithHost:host action:@"AppStore" token:token sessionKey:sessionKey];
}

+ (void)reportWithHost:(NSString *)host action:(NSString *)action token:(NSString *)token sessionKey:(NSString *)sessionKey {
    
    if (![PIUtil validStr:host]) {
        NSLog(@"[PIReport] init error: invalid key");
        return;
    }
    if (![PIUtil validStr:action]) {
        NSLog(@"[PIReport] end play report error: action is invalid");
        return;
    }
    if (![PIUtil validStr:token]) {
        NSLog(@"[PIReport] end play report error: token is invalid");
        return;
    }
    if (![PIUtil validStr:sessionKey]) {
        NSLog(@"[PIReport] end play report error: sessionKey is invalid");
        return;
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/user/report/", host];
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:token forKey:@"token"];
    [params setValue:sessionKey forKey:@"session_key"];
    [params setValue:action forKey:@"action"];
    [PIHttpManager post:urlStr params:params success:^(NSDictionary * _Nonnull result) {
        NSLog(@"[PIReport] endplay report result: %@", result);
    } failure:^(NSDictionary * _Nonnull error) {
        NSLog(@"[PIReport] endplay report error: %@", error);
    }];
}

@end
