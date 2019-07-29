//
//  PITouchView.m
//  CloudGame
//
//  Created by A on 2019/1/21.
//  Copyright © 2019年 A. All rights reserved.
//

#import "PITouchView.h"

typedef enum : uint {
    TouchPhaseBegan,
    TouchPhaseMoved,
    TouchPhaseEnded,
} TouchPhase;

@implementation PITouchView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.multipleTouchEnabled = YES;
    }
    return self;
}

- (NSData *)composeTouches:(NSSet<UITouch *> *)touches withPhase:(TouchPhase)phase {
    
    CGSize selfSize = [self bounds].size;
    NSMutableDictionary *touchDict = [NSMutableDictionary new];
    
    int i = 0;
    for (UITouch *touch in touches) {
        
        CGPoint point = [touch locationInView:self];
        NSString *controlStr = [NSString stringWithFormat:@"%f_%f_%d_0_0", point.x/selfSize.width, point.y/selfSize.height, phase];
        [touchDict setValue:controlStr forKey:[NSString stringWithFormat:@"%d", i]];
        ++i;
    }
    
    if (touchDict == nil) {
        NSLog(@"[PITouchView] composeTouches failed: touchDict is nil");
        return nil;
    }
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:touchDict options:0x0 error:&err];
    if (err) {
        NSLog(@"[PITouchView] composeTouches failed: json error: %@", err);
        return nil;
    }
    return data;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSData *data = [self composeTouches:touches withPhase:TouchPhaseBegan];
   // NSLog(@"PITouchView began: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (data == nil) { return; }
    
    if ([self.delegate respondsToSelector:@selector(onPITouchViewTouched:)]) {
        [self.delegate onPITouchViewTouched:data];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSData *data = [self composeTouches:touches withPhase:TouchPhaseMoved];
    //NSLog(@"PITouchView moved: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (data == nil) { return; }
    
    if ([self.delegate respondsToSelector:@selector(onPITouchViewTouched:)]) {
        [self.delegate onPITouchViewTouched:data];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSData *data = [self composeTouches:touches withPhase:TouchPhaseEnded];
    //NSLog(@"PITouchView ended: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (data == nil) { return; }
    
    if ([self.delegate respondsToSelector:@selector(onPITouchViewTouched:)]) {
        [self.delegate onPITouchViewTouched:data];
    }
}

- (void)dealloc {
    
    NSLog(@"***** [%@ dealloc] *****", [self class]);
}

@end

/*
 x/w:触摸点x相对于屏幕宽的比例
 y/h:触摸点y相对于屏幕高的比例
 parse:触摸类型, 0->手指头按下, 1->手指头移动, 2->手指头抬起
 size:点击面积（iOS无，用0）
 pressure:点击压力（iOS无，用0）
 finger_id_0:指头ID（iOS用不上，用累加数字）
 {
     "finger_id_0" : "x/w_y/h_parse_size_pressure",
     "finger_id_1" : "x/w_y/h_parse_size_pressure",
     "finger_id_2" : "x/w_y/h_parse_size_pressure"
 }
 */
