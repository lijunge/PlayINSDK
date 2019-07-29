//
//  PIUtil.h
//  playin
//
//  Created by A on 2019/2/18.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIUtil : NSObject

+ (UIViewController *)rootViewController;
+ (BOOL)validObj:(id)obj;
+ (BOOL)validStr:(NSString *)str;
+ (NSData *)dataFromHexString:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
