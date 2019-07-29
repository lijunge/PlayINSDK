//
//  PIVideoDisplay.h
//  playin
//
//  Created by A on 2017/10/19.
//  Copyright © 2017年 A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PIVideoDisplay : UIView
- (instancetype)initWithFrame:(CGRect)frame;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)displayLastPixelImageBuffer:(CVImageBufferRef)imageBuffer;
@end
