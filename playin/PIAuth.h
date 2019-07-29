//
//  PIAuth.h
//  playin
//
//  Created by A on 2019/5/9.
//  Copyright © 2019年 lijunge. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^PIAuthSuccess)(NSString * sessionKey);
typedef void(^PIAuthFailure)(NSString * error);

@interface PIAuth : NSObject
+ (void)authWithHost:(NSString *)host key:(NSString *)key success:(PIAuthSuccess)success failure:(PIAuthFailure)failure;
@end

NS_ASSUME_NONNULL_END
