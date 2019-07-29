//
//  PIStream.h
//  playin
//
//  Created by 城门虾米 on 2019/5/20.
//  Copyright © 2019 lijunge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PISocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PIStreamDelegate <NSObject>

@optional

- (void)onPIStreamEnded:(NSError *)error;
- (void)onPIStreamRegisterSuccess:(NSDictionary *)result;
- (void)onPIStreamRegisterFailure:(NSString *)error;
- (void)onPIStreamReceivedVideoData:(NSData *)data;
- (void)onPIStreamReceivedAudioData:(NSData *)data;

@end

@interface PIStream : NSObject <PISocketDelegate>

@property (nonatomic, weak) id<PIStreamDelegate> delegate;

/**
 * 开启流传输
 * @param duration 表明这次会话持续时间
 * @return YES表明成功调用函数，NO表明参数不正确
 */
- (BOOL)startStreamWithToken:(NSString *)token
            deviceName:(NSString *)deviceName
                  host:(NSString *)host
                  port:(NSInteger)port
                    duration:(uint)duration;

/**
 * 主动停止流
 */
- (void)stopStream;

/**
 *
 */
- (void)sendTouchData:(NSData *)touchData;




@end


NS_ASSUME_NONNULL_END
