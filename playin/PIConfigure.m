//
//  PIConfigure.m
//  playin
//
//  Created by A on 2019/4/4.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PIConfigure.h"
#import "PIUtil.h"

@interface PIConfigure()
@property (nonatomic, strong) NSDictionary *cfg;
@end

@implementation PIConfigure

- (instancetype)init {
    
    if (self = [super init]) {
        self.cfg = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary *)config {
    
    return (NSDictionary *)self.cfg;
}

- (NSString *)host {
    
    return [self.cfg valueForKey:@"host"];
}

- (void)fetchWithSuccess:(void(^)(NSDictionary *result))success failure:(void(^)(NSDictionary *error))failure {
    
    NSString *urlStr = @"https://playinair.com/config";
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data,
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
                
                id code = [dict valueForKey:@"code"];
                if (![PIUtil validObj:code]) {
                    NSLog(@"[PIConfigure] request error: valid code");
                    return;
                }
                
                int code_value = [code intValue];
                if (code_value == 0) {
                    NSDictionary *data = [dict valueForKey:@"data"];
                    if (![PIUtil validObj:data]) {
                        NSLog(@"[PIConfigure] request error: valid data");
                        return;
                    }
                    self.cfg = data;
                    if (success) {
                        success(data);
                    }
                } else {
                    NSString *errStr = [dict valueForKey:@"error"];
                    NSLog(@"[PIConfigure] request failure: %@", errStr);
                    if (failure) {
                        failure(@{@"info" : errStr});
                    }
                }
            }
        }
    }];
    [dataTask resume];
}

- (NSDictionary *)errorInfoWithObject:(id)object {
    
    if (object) {
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSString *class = NSStringFromClass([self class]);
        [params setValue:class forKey:object];
        return params;
    }
    return nil;
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}

//
//+ (void)load {
//    
//    NSLog(@"[PIConfigure] load");
//    dispatch_queue_t queue = dispatch_queue_create("com.playin.config", NULL);
//    dispatch_sync(queue, ^{
//        [PIConfigure.shared fetchWithSuccess:^(NSDictionary * _Nonnull result) {
//            NSLog(@"[PIConfigure] configure result: %@", result);
//        } failure:^(NSDictionary * _Nonnull error) {
//            NSLog(@"[PIConfigure] configure error: %@", error);
//        }];
//    });
//}
//
//__attribute__((constructor)) static void entry() {
//
//    [PIConfigure.shared fetchWithSuccess:^(NSDictionary * _Nonnull result) {
//        NSLog(@"[PIConfigure] configure result: %@", result);
//    } failure:^(NSDictionary * _Nonnull error) {
//        NSLog(@"[PIConfigure] configure error: %@", error);
//    }];
//}

@end
