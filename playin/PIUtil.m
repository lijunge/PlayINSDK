//
//  PIUtil.m
//  playin
//
//  Created by A on 2019/2/18.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PIUtil.h"

@implementation PIUtil

+ (UIWindow *)currentWindow {
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    return window;
}

+ (UIViewController *)rootViewController {
    
    UIWindow *window = [self currentWindow];
    UIViewController *topVC = [self topViewController:window.rootViewController];
    return topVC;
    
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController {
    
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [self topViewController:[navigationController.viewControllers lastObject]];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootViewController;
        return [self topViewController:tabController.selectedViewController];
    }
    if (rootViewController.presentedViewController) {
        return [self topViewController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

+ (BOOL)validObj:(id)obj {
    
    if (obj == nil) {
        return NO;
    }
    if ([obj isKindOfClass:[NSNull class]]) {
        return NO;
    }
    return YES;
}

+ (BOOL)validStr:(NSString *)str {
    
    if (![self validObj:str]) {
        return NO;
    }
    if (![str isKindOfClass:[NSString class]]) {
        return NO;
    }
    if ([str length] == 0) {
        return NO;
    }
    return YES;
}

+ (NSData *)dataFromHexString:(NSString *)str {
    
    str = [str lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    long length = str.length;
    while (i < length-1) {
        char c = [str characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [str characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

@end
