//
//  PIReport.h
//  playin
//
//  Created by lijunge on 2019/5/6.
//  Copyright © 2019 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIReport : NSObject

+ (void)reportPlayEndWithHost:(NSString *)host token:(NSString *)token sessionKey:(NSString *)sessionKey;

+ (void)reportAppStoreWithHost:(NSString *)host token:(NSString *)token sessionKey:(NSString *)sessionKey;

@end

NS_ASSUME_NONNULL_END
