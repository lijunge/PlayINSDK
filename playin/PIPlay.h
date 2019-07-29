//
//  PIPlay.h
//  playin
//
//  Created by A on 2019/5/9.
//  Copyright © 2019年 lijunge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayInView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PIPlaySuccess)(NSDictionary *result);
typedef void(^PIPlayFailure)(NSString *error);

@protocol PIPlayDelegate <NSObject>
- (void)onPIPlayError:(NSString *)error;
- (void)onPIPlayStarted;
- (void)onPIPlayContinue;
- (void)onPIPlayClosed;
- (void)onPIPlayInstall;
- (void)onPIPlaySocketEnd;
@end

@interface PIPlay : NSObject

@property (nonatomic, weak) id<PIPlayDelegate> delegate;
@property (nonatomic, strong) PlayInView *playInView;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)startWithHost:(NSString *)host
                 port:(uint16_t)port
                token:(NSString *)token
             duration:(int)duration
          orientation:(int)orientation
         continueText:(NSString *)continueText
          installText:(NSString *)installText
              failure:(PIPlayFailure)failure;

- (void)countdown:(int)count;
- (void)updateCurrentPlayTimes:(int)cTimes totalPlayTimes:(int)tTimes;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
