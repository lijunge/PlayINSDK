//
//  PIGameView.h
//  playin
//
//  Created by lijunge on 2019/5/5.
//  Copyright © 2019 A. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIGameView : UIView

- (void)startPlayInGame;
- (void)finishPlayInGame;
- (void)gameDurationCountdown:(int)time;
- (void)configGameViewOrientation:(NSInteger)orientation;

@end

NS_ASSUME_NONNULL_END
