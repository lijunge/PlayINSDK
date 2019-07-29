//
//  PIPingHelper.m
//  playin
//
//  Created by A on 2019/4/2.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PIPingHelper.h"
#import "PICommon.h"
#import "PIHttpManager.h"
#import "PIPing.h"
#import "PIUtil.h"

@interface PIPingHelper() <PIPingDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *pings;
@property (nonatomic, strong) NSMutableDictionary *result;
@property (nonatomic, copy) PIPingSuccess successCallback;
@property (nonatomic, copy) PIPingFailure failureCallback;
@end

@implementation PIPingHelper {
    
    int timerCount;
    int countTimes;
    BOOL started;
    dispatch_queue_t queue;
}

- (instancetype)init {
    
    if (self = [super init]) {
        timerCount = 0;
        started = NO;
        self.pings = [NSMutableArray new];
        self.result = [NSMutableDictionary new];
    }
    return self;
}

- (void)startWithHosts:(NSArray *)hosts times:(int)times success:(PIPingSuccess)success failure:(PIPingFailure)failure {
    
    if (started == YES) {
        NSLog(@"[PIPingHelper] repeat ping");
        return;
    }
    
    if (times < 1) {
        NSError *err = [self errorWithInfo:@"times must >= 1"];
        if (failure) {
            failure(err);
        }
        started = NO;
        return;
    }
    
    countTimes = times;
    self.successCallback = success;
    self.failureCallback = failure;
    
    for (NSString *host in hosts) {
        if (![PIUtil validStr:host]) {
            continue;
        }
        PIPing *ping = [[PIPing alloc] initWithHostName:host];
        ping.delegate = self;
        [self.pings addObject:ping];
        
        NSMutableArray *pingResults = [[NSMutableArray alloc] initWithCapacity:countTimes];
        [self.result setValue:pingResults forKey:host];
    }
    
    __weak typeof(self) weakself = self;
    queue = dispatch_queue_create("com.playin.ping", NULL);
    dispatch_async(queue, ^{
        //NSLog(@"[PIPingHelper] hosts: %@ times: %d: weakself: %@", hosts, times, weakself);
        weakself.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:weakself selector:@selector(onTimer) userInfo:nil repeats:YES];
        [weakself.timer setFireDate:[NSDate date]];
        [[NSRunLoop currentRunLoop] addTimer:weakself.timer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (NSError *)errorWithInfo:(NSString *)info {
    
    NSError *err = [NSError errorWithDomain:@"PIPingHelper" code:1 userInfo:@{ @"info" : info }];
    return err;
}

- (void)onTimer {
    
    //NSLog(@"[PIPingHelper] onTimer: %d", timerCount);
    started = YES;
    if (timerCount < countTimes) {
        for (PIPing *ping in self.pings) {
            [ping stop];
            [ping start];
        }
    } else {
        [self timeUp];
    }
    timerCount++;
}

- (void)timeUp {
    
    [self.timer invalidate];
    self.timer = nil;
    started = NO;
    
    if (self.successCallback) {
        self.successCallback(self.result);
    }
    self.pings = nil;
}

#pragma mark - PIPingDelegate
- (void)pi_ping:(PIPing *)pinger didStartWithAddress:(NSData *)address {
    
    NSData *packet = [pinger packetWithPingData:nil];
    [pinger sendPacket:packet];
}

- (void)pi_ping:(PIPing *)pinger didFailWithError:(NSError *)error {
    
    [pinger stop];
}

- (void)pi_ping:(PIPing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    
    //NSLog(@"%s\t%@\t%d", __func__, pinger.hostName, sequenceNumber);
    [pinger stop];
}

- (void)pi_ping:(PIPing *)pinger didReceivePingResponsePacket:(NSData *)packet timeToLive:(NSInteger)timeToLive sequenceNumber:(uint16_t)sequenceNumber timeElapsed:(NSTimeInterval)timeElapsed {
    
    NSString *host = pinger.hostName;
    if (![PIUtil validStr:host]) {
        host = pinger.IPAddress;
    }
    NSNumber *time = [NSNumber numberWithDouble:timeElapsed*1000];
    if ([PIUtil validStr:host] && [PIUtil validObj:time]) {
        NSMutableArray *pingResult = [self.result valueForKey:host];
        [pingResult addObject:time];
    }
    //NSLog(@"[PIPingHelper] %@\t%d\t%.1f", host, sequenceNumber, timeElapsed*1000);
    //NSLog(@"[PIPingHelper] %@", self.result);
}

- (void)pi_ping:(PIPing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    //NSLog(@"%s %@ %d", __func__, pinger.hostName, sequenceNumber);
}

- (void)pi_ping:(PIPing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    
    //NSLog(@"%s %@", __func__, pinger.hostName); // TODO: may be a bug
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}

@end
