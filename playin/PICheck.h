//
//  PICheck.h
//  playin
//
//  Created by lijunge on 2019/5/8.
//  Copyright © 2019 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PICheck : NSObject

+ (void)checkAvaliableWithHost:(NSString *)host
                          adid:(NSString *)adid
                    sessionKey:(NSString *)sessionKey
                         pings:(NSDictionary *)pings
                      callback:(void(^)(BOOL result))avaliable;

@end

NS_ASSUME_NONNULL_END
