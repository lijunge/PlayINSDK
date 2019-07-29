//
//  PIHttpManager.h
//  pid
//
//  Created by A on 2019/2/12.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^PIHttpManagerSuccess)(NSDictionary *result);
typedef void(^PIHttpManagerFailure)(NSDictionary *error);

@interface PIHttpManager : NSObject
+ (void)post:(NSString *)urlStr params:(NSDictionary *)params success:(PIHttpManagerSuccess)success failure:(PIHttpManagerFailure)failure;
+ (void)get:(NSString *)urlStr params:(NSDictionary *)params success:(PIHttpManagerSuccess)success failure:(PIHttpManagerFailure)failure;
@end

NS_ASSUME_NONNULL_END
