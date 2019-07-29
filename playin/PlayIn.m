//
//  PlayIn.m
//  playin
//
//  Created by A on 2019/2/12.
//  Copyright © 2019年 A. All rights reserved.
//
// TODO: 关闭按钮改成悬浮
// TODO: 流服务器重连

#import "PlayIn.h"
#import "PIHttpManager.h"
#import "PIUtil.h"
#import "PITouchView.h"
#import "PIVideoDecode.h"
#import "PIVideoDisplay.h"
#import "PlayInView.h"
#import "PIDeviceInfo.h"
#import "PIPingHelper.h"
#import "PIConfigure.h"
#import "PIReport.h"
#import "PICheck.h"
#import "PIPlay.h"
#import "PICommon.h"
#import "PIAuth.h"

@interface PlayIn () <PIPlayDelegate>
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *sessionKey;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSArray *streams; // stream servers
@property (nonatomic, assign) int pingTimes;    // ping times
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, strong) PIPingHelper *pingHelper;
@property (nonatomic, strong) PIPlay *play;
@property (nonatomic, strong) PIConfigure *configure; // diff from PlayInConfig
@property (nonatomic, copy) PlayInConfigureCompletion completion;
@property (nonatomic, copy) PlayInPlayCompletion playCompletion;
@property (nonatomic, strong) NSString *sdkKey;
@property (nonatomic, strong) NSString *adid;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) double serverDuration;
@property (nonatomic, assign) double singlePlayDuration;
@property (nonatomic, assign) double userDuration;
@property (nonatomic, assign) int playTimes;
@property (nonatomic, assign) int playCount;
@property (nonatomic, assign) int background;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL suspending;
@end

static PlayIn * _instance = nil;

@implementation PlayIn

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)sharedInstance {
    
    if (_instance == nil) {
        _instance = [super new];
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    
    return _instance;
}

- (void)configureWithKey:(NSString *)key completionHandler:(PlayInConfigureCompletion)completion {
    
    /*-- check key --*/
    if (![PIUtil validStr:key]) {
        if (completion) {
            completion(NO, @"[PlayIn] configureWithKey: invalid key");
        }
        return;
    }
    self.sdkKey = key;
    self.completion = completion;
    __weak typeof(self) weakself = self;
    self.configure = [PIConfigure new];
    [self.configure fetchWithSuccess:^(NSDictionary * _Nonnull result) {
        
        NSString *host = [result valueForKey:@"host"];
        NSDictionary *stParams = [result valueForKey:@"speed_test"];
        self.streams = [stParams valueForKey:@"streams"];
        self.pingTimes = [[stParams valueForKey:@"speed_test_count"] intValue];
        
        if ([PIUtil validStr:host]) {
            weakself.host = host;
            [PIAuth authWithHost:host key:weakself.sdkKey success:^(NSString * _Nonnull sessionKey) {
                weakself.started = NO;
                weakself.suspending = NO;
                weakself.serverDuration = 0.0;
                weakself.playCount = 0;
                weakself.sessionKey = sessionKey;
                weakself.pingHelper = [PIPingHelper new];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself setupTimer];
                });
                //[weakself addObservers];
                weakself.background = [[NSDate date] timeIntervalSince1970];
                if (weakself.completion) {
                    weakself.completion(YES, nil);
                }
            } failure:^(NSString * _Nonnull error) {
                NSLog(@"[PlayIn] configureWithKey: internal auth error: %@", error);
                if (weakself.completion) {
                    weakself.completion(NO, @"[PlayIn] configureWithKey: internal auth error");
                }
            }];
            
        } else {
            if (weakself.completion) {
                weakself.completion(NO, @"[PlayIn] configureWithKey: internal configure error");
            }
        }
        weakself.configure = nil;
    } failure:^(NSDictionary * _Nonnull error) {
        NSLog(@"[PlayIn] configureWithKey: internal auth error net: %@", error);
        if (weakself.completion) {
            weakself.completion(NO, @"[PlayIn] configureWithKey: internal configure error");
        }
        weakself.configure = nil;
    }];
}

- (void)checkAvailabilityWithAdid:(NSString *)adid completionHandler:(void(^)(BOOL result))avaliable {
    
    /*-- check adid --*/
    if (![PIUtil validStr:adid]) {
        if (avaliable) {
            avaliable(NO);
        }
        return;
    }
    self.adid = adid;
    // auth -> net speed test -> check -> play
    __weak typeof(self) weakself = self;
    if (![PIUtil validStr:self.adid] ||
        ![PIUtil validStr:self.sessionKey]) {
        NSLog(@"[PlayIn] check error: adid or sessionKey is invalid");
        if (avaliable) avaliable(NO);
        return;
    } else {
        if (![PIUtil validObj:self.streams]) {
            [PICheck checkAvaliableWithHost:self.host adid:self.adid sessionKey:self.sessionKey pings:@{} callback:^(BOOL result) {
                if (avaliable) avaliable(result);
            }];
        } else {
            [self.pingHelper startWithHosts:self.streams times:self.pingTimes success:^(NSDictionary * _Nonnull result) {
                [PICheck checkAvaliableWithHost:weakself.host adid:weakself.adid sessionKey:weakself.sessionKey pings:result callback:^(BOOL result) {
                    if (avaliable) avaliable(result);
                    weakself.pingHelper = nil;
                }];
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"[PlayIn] ping error: %@", error);
                [PICheck checkAvaliableWithHost:weakself.host adid:weakself.adid sessionKey:weakself.sessionKey pings:@{} callback:^(BOOL result) {
                    if (avaliable) avaliable(result);
                    weakself.pingHelper = nil;
                }];
            }];
        }
    }
}

- (void)playWithOriginPoint:(CGPoint)origin
                   duration:(NSInteger)duration
                      times:(NSInteger)times
          completionHandler:(PlayInPlayCompletion)completion {
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    self.frame = CGRectMake(origin.x, origin.y, screenWidth, screenHeight);
    
    /*-- check times --*/
    if (times <= 0) {
        [self handleStartResultWithCode:PIErrorParams object:@"invalid times(times > 0)"];
        return;
    }
    self.playTimes = (int)(times >= 2 ? 2 : times);
    
    /*-- check duration --*/
    if (duration <= 0) {
        [self handleStartResultWithCode:PIErrorParams object:@"invalid duration(0 < duration <= max)"];
        return;
    }
    self.userDuration = duration;
    self.singlePlayDuration = duration / self.playTimes;
    self.playCompletion = completion;
    [self start];
}

- (void)setupTimer {
    
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(onTimer)
                                                         userInfo:nil
                                                          repeats:YES];
    
    [self.countdownTimer setFireDate:[NSDate distantFuture]];
}

- (void)onTimer {
    
    if (self.playCount < self.playTimes && !self.suspending) {
        if (self.singlePlayDuration >= 1) {
            [self.play countdown:self.singlePlayDuration];
        } else if (self.singlePlayDuration < 1) {
            [self singlePlayDurationTimesup];
        }
        self.singlePlayDuration -= 1;
    }
    self.serverDuration -= 1;
   
    if (self.serverDuration <= 0) {
        [self serverTerminate];
    }
}

- (void)singlePlayDurationTimesup {
    
    self.suspending = YES;
    self.playCount++;
    [self.countdownTimer setFireDate:[NSDate distantFuture]];
    [self.play updateCurrentPlayTimes:self.playCount totalPlayTimes:self.playTimes];
    if (self.playCount == self.playTimes) {
        [self playTimeUp];
    }
}

#pragma mark - observers
- (void)addObservers {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)didBecomeActive {
    
    int bgTime = [[NSDate date] timeIntervalSince1970] - self.background;
    self.serverDuration -= bgTime;
    self.singlePlayDuration -= bgTime;
    self.background = [[NSDate date] timeIntervalSince1970];
    self.countdownTimer.fireDate = [NSDate date];
}

- (void)willResignActive {
    
    self.background = [[NSDate date] timeIntervalSince1970];
    self.countdownTimer.fireDate = [NSDate distantFuture];
}

- (void)didEnterBackground {
    
    self.background = [[NSDate date] timeIntervalSince1970];
    self.countdownTimer.fireDate = [NSDate distantFuture];
}

- (void)willEnterForeground {
    
    int bgTime = [[NSDate date] timeIntervalSince1970] - self.background;
    self.serverDuration -= bgTime;
    self.singlePlayDuration -= bgTime;
    self.background = [[NSDate date] timeIntervalSince1970];
    self.countdownTimer.fireDate = [NSDate date];
}

- (void)start {
    
    if (![PIUtil validStr:self.adid]) {
        NSLog(@"[PlayIn] start error: invalid adid");
        [self handleStartResultWithCode:PIErrorParams object:@"invalid adid"];
        return;
    }
    
    if (![PIUtil validStr:self.sdkKey]) {
        NSLog(@"[PlayIn] start error: invalid sdkKey");
        [self handleStartResultWithCode:PIErrorParams object:@"invalid sdkKey"];
        return;
    }
    
    if (![PIUtil validStr:self.sessionKey]) {
        NSLog(@"[PlayIn] start error: invalid sessionKey");
        [self handleStartResultWithCode:PIErrorParams object:@"invalid sessionKey"];
        return;
    }
    
    if (self.started == YES) { // 正在试玩，拒绝
        NSLog(@"[PlayIn] start error: duplicate playing");
        [self handleStartResultWithCode:PIErrorDuplicate object:@"duplicate playing"];
        return;
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/user/actions/play", self.host];
    NSMutableDictionary *playParams = [NSMutableDictionary new];
    [playParams setValue:[NSNumber numberWithInt:1] forKey:@"os_type"];
    [playParams setValue:self.sdkKey forKey:@"sdk_key"];
    [playParams setValue:self.sessionKey forKey:@"session_key"];
    [playParams setValue:self.adid forKey:@"ad_id"];
    [playParams setValue:[PIDeviceInfo idfa] forKey:@"sdk_device_id"];
    [playParams setValue:PlayInVersion forKey:@"sdk_version"];
    
    __weak typeof(self) weakself = self;
    [PIHttpManager post:urlStr params:playParams success:^(NSDictionary * _Nonnull result) {
        NSLog(@"[PlayIn] play result: %@", result);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself startWithParams:result];
        });
    } failure:^(NSDictionary * _Nonnull error) {
        NSLog(@"[PlayIn] play error: %@", error);
        NSString *eInfo = [error valueForKey:@"PIHttpManager"];
        [self handleStartResultWithCode:PIErrorNetwork object:eInfo];
    }];
}

- (void)startWithParams:(NSDictionary *)params {
    
    id code = [params valueForKey:@"code"];
    if (![PIUtil validObj:code]) {
        [self handleStartResultWithCode:PIErrorInner object:@"inner error"];
        return;
    }
    int code_value = [code intValue];
    if (code_value == 0) {
        NSDictionary *tmpParams = [params valueForKey:@"data"];
        self.play = [[PIPlay alloc] initWithFrame:self.frame];
        self.play.delegate = self;
        NSString *streamHost = [tmpParams valueForKey:@"stream_server_ip"];
        NSString *token = [tmpParams valueForKey:@"token"];
        NSString *continueString = [tmpParams valueForKey:@"continue_text"];
        NSString *installString = [tmpParams valueForKey:@"install_text"];
        id portObj = [tmpParams valueForKey:@"stream_server_port"];
        id serverDurationObj = [tmpParams valueForKey:@"duration"];
        id orientationObj = [tmpParams valueForKey:@"orientation"];
        
        if (![PIUtil validStr:streamHost] ||
            ![PIUtil validStr:token] ||
            ![PIUtil validObj:portObj] ||
            ![PIUtil validObj:serverDurationObj] ||
            ![PIUtil validObj:orientationObj]) { // necessary params
            [self handleStartResultWithCode:PIErrorInner object:@"inner error"];
            return;
        }
        
        uint16_t port = (uint16_t)[portObj integerValue];
        self.serverDuration = [serverDurationObj intValue];
        self.userDuration = self.userDuration > self.serverDuration ? self.serverDuration : self.userDuration;
        self.singlePlayDuration = self.userDuration / self.playTimes;
        self.token = token;
        int orientation = [orientationObj intValue];
        
        __weak typeof(self) weakself = self;
        [self.play startWithHost:streamHost port:port token:token duration:self.serverDuration orientation:orientation continueText:continueString installText:installString failure:^(NSString * _Nonnull error) {
            weakself.started = NO;
        }];
        [self addObservers];
    } else {
        NSString *errStr = [params valueForKey:@"error"];
        NSLog(@"[PlayIn] play failure: %@", errStr);
        [self handleStartResultWithCode:PIErrorInner object:errStr];
    }
}

- (void)serverTerminate {
    
    [self destroyTimer];
    [self resetStatus];
    [self tellDelegateTerminate];
}

- (void)playTimeUp {
    
    //试玩时间结束
    [self reportEnd];
}

- (void)resetStatus {
    
    self.singlePlayDuration = 0.0;
    self.serverDuration = 0.0;
    self.started = NO;
    self.suspending = NO;
}

- (void)destroyTimer {
    
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
}

- (void)tellDelegateTerminate {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInTerminate)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onPlayInTerminate];
        });
    }
}

- (void)stopPlay {
    
    NSLog(@"[PlayIn] stopPlay");
    [self.play stop];
}

- (void)reportEnd {
    
    [PIReport reportPlayEndWithHost:self.host token:self.token sessionKey:self.sessionKey];
}

- (void)handleStartResultWithCode:(PIError)code object:(id)object {

    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSNumber *codeNum = [NSNumber numberWithInteger:code];
        [params setValue:codeNum forKey:@"code"];
        if (code == PIErrorNone) {
            self.playInView.hidden = NO;
            [params setValue:object forKey:@"info"];
            self.playCompletion(params);
        } else {
            self.playInView.hidden = YES;
            NSString *errStr = [NSString stringWithFormat:@"%@", object];
            [params setValue:errStr forKey:@"info"];
            self.playCompletion(params);
        }
    });
}

#pragma mark - PIPlayDelegate

- (void)onPIPlayError:(NSString *)error {
    
    [self stopPlay];
    [self destroyTimer];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInError:)]) {
        [self.delegate onPlayInError:error];
    }
}

- (void)onPIPlayStarted {
    
    [self.countdownTimer setFireDate:[NSDate date]];
    self.started = YES;
    self.playInView = self.play.playInView;
    NSDictionary *tmpInfoDic = @{@"duration": [NSNumber numberWithDouble:self.userDuration]};
    [self handleStartResultWithCode:PIErrorNone object:tmpInfoDic];
}

- (void)onPIPlayContinue {
    
    self.started = YES;
    self.suspending = NO;
    self.singlePlayDuration = self.userDuration / self.playTimes;
    [self.countdownTimer setFireDate:[NSDate date]];
}

- (void)onPIPlayClosed {
    
    [self destroyTimer];
    [self reportEnd];
    [self stopPlay];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInCloseAction)]) {
        [self.delegate onPlayInCloseAction];
    }
}

- (void)onPIPlayInstall {

    [self destroyTimer];
    [self stopPlay];
    [PIReport reportAppStoreWithHost:self.host token:self.token sessionKey:self.sessionKey];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayInInstallAction)]) {
        [self.delegate onPlayInInstallAction];
    }
}

- (void)onPIPlaySocketEnd {
 
    [self destroyTimer];
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


/** dealloc
PlayIn              ok
PIPlay              ok
PIConfigure         ok
PIDownloadView      ok
PIGameView          ok
PIGCDAsyncSocket    ok
PIPing              ok
PIPingHelper        ok
PISocketManager     ok
PITouchView         ok
PIVideoDisplay      ok
PlayInView          ok
**/
