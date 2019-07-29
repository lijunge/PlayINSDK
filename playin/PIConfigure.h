//
//  PIConfigure.h
//  playin
//
//  Created by A on 2019/4/4.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIConfigure : NSObject
- (NSString *)host;
- (NSDictionary *)config;
- (void)fetchWithSuccess:(void(^)(NSDictionary *result))success failure:(void(^)(NSDictionary *error))failure;
@end

NS_ASSUME_NONNULL_END
