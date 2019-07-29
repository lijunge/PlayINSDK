//
//  PISocket.h
//  sdk
//
//  Created by 城门虾米 on 2019/5/9.
//  Copyright © 2019 虾米城门. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"



NS_ASSUME_NONNULL_BEGIN


@protocol PISocketDelegate;
@interface PISocket : NSObject

- (id)initWithDelegate:(nullable id<PISocketDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;


- (BOOL)connectToHost:(NSString *)host
               onPort:(uint16_t)port
          withTimeout:(int)timeout
                error:(NSError **)errPtr;

- (void)writeData:(NSData *) data;

- (void)sendMessageWithMsgID:(int)msgid Data:(NSDictionary*)data;
- (void)sendStreamData:(NSData*)data;
- (void)disconnect;
- (void)sendMessageToAndroid;
@end

@protocol PISocketDelegate <NSObject>
@optional

- (void)socketDidConnect:(PISocket *)sock;
- (void)socketDidDisconnect:(PISocket *)sock withError:(nullable NSError *)err;

- (void)socket:(PISocket *)sock didReadPacket:(NSData *)packet;


@end


NS_ASSUME_NONNULL_END
