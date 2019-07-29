//
//  PIHttpManager.m
//  pid
//
//  Created by A on 2019/2/12.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PIHttpManager.h"
#import "PIUtil.h"

@implementation PIHttpManager

+ (void)post:(NSString *)urlStr params:(NSDictionary *)params success:(PIHttpManagerSuccess)success failure:(PIHttpManagerFailure)failure {
    
    if (![PIUtil validStr:urlStr]) {
        if (failure) {
            failure([self errorInfoWithObject:@"urlStr can't be nil"]);
        }
        return;
    }
    
    if (params == nil) {
        if (failure) {
            failure([self errorInfoWithObject:@"params can't be nil"]);
        }
        return;
    }
    
    NSError *err = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:params options:0x0 error:&err];
    if (err != nil) {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    
    NSString *sid = [params valueForKey:@"session_key"];
    if (sid) {
        [request setValue:sid forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data,
                                                                                      NSURLResponse * _Nullable response,
                                                                                      NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger responseStatusCode = [httpResponse statusCode];
        
        if (error) {
            if (failure) {
                failure([self errorInfoWithObject:error]);
            }
        } else if (responseStatusCode != 200) {
            if (failure) {
                failure([self errorInfoWithObject:@"statusCode != 200"]);
            }
        } else if (!data) {
            if (failure) {
                failure([self errorInfoWithObject:@"return data is nil"]);
            }
        } else {
            NSError *jsonErr = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonErr];
            if (jsonErr) {
                if (failure) {
                    failure([self errorInfoWithObject:@"json error"]);
                }
            } else {
                if (success) {
                    success(dict);
                }
            }
        }
    }];
    [task resume];
}

+ (void)get:(NSString *)urlStr params:(NSDictionary *)params success:(PIHttpManagerSuccess)success failure:(PIHttpManagerFailure)failure {
    
    if (![PIUtil validStr:urlStr]) {
        if (failure) {
            failure([self errorInfoWithObject:@"urlStr can't be nil"]);
        }
        return;
    }
    
    NSString *sessionKey = [params valueForKey:@"session_key"];
    if (![PIUtil validStr:sessionKey]) {
        if (failure) {
            failure([self errorInfoWithObject:@"sessionKey can't be nil"]);
        }
        return;
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:sessionKey forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data,
                                                                                      NSURLResponse * _Nullable response,
                                                                                      NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger responseStatusCode = [httpResponse statusCode];
        
        if (error) {
            if (failure) {
                failure([self errorInfoWithObject:error]);
            }
        } else if (responseStatusCode != 200) {
            if (failure) {
                failure([self errorInfoWithObject:@"statusCode != 200"]);
            }
        } else if (!data) {
            if (failure) {
                failure([self errorInfoWithObject:@"return data is nil"]);
            }
        } else {
            NSError *jsonErr = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonErr];
            if (jsonErr) {
                if (failure) {
                    failure([self errorInfoWithObject:@"json error"]);
                }
            } else {
                if (success) {
                    success(dict);
                }
            }
        }
    }];
    
    [task resume];
}

+ (NSDictionary *)errorInfoWithObject:(id)object {
    
    if (object) {
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSString *class = NSStringFromClass([self class]);
        [params setValue:class forKey:object];
        return params;
    }
    return nil;
}

@end
