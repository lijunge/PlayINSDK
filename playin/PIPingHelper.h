//
//  PIPingHelper.h
//  playin
//
//  Created by A on 2019/4/2.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^PIPingSuccess)(NSDictionary *result);
typedef void(^PIPingFailure)(NSError *error);

@interface PIPingHelper : NSObject
//+ (PIPingHelper *)shared;
- (void)startWithHosts:(NSArray *)hosts times:(int)times success:(PIPingSuccess)success failure:(PIPingFailure)failure;
@end

NS_ASSUME_NONNULL_END
