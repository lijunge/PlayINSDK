//
//  PIVideoDecode.h
//  playin
//
//  Created by A on 2017/10/17.
//  Copyright © 2017年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

#if SDL_BYTEORDER == SDL_LIL_ENDIAN
#   define SDL_FOURCC(a, b, c, d) \
(((uint32_t)a) | (((uint32_t)b) << 8) | (((uint32_t)c) << 16) | (((uint32_t)d) << 24))
#   define SDL_TWOCC(a, b) \
((uint16_t)(a) | ((uint16_t)(b) << 8))
#else
#   define SDL_FOURCC(a, b, c, d) \
(((uint32_t)d) | (((uint32_t)c) << 8) | (((uint32_t)b) << 16) | (((uint32_t)a) << 24))
#   define SDL_TWOCC( a, b ) \
((uint16_t)(b) | ((uint16_t)(a) << 8))
#endif

#define IJK_VTB_FCC_AVCC   SDL_FOURCC('C', 'c', 'v', 'a')

@protocol PIVideoDecodeDelegate <NSObject>

- (void)PIVideoDecodeDidDecode:(CVImageBufferRef)imageBuffer;

@end

typedef void(^PIVideoDecodeCompletionHandle)(CVImageBufferRef imageBuffer);

@interface PIVideoDecode : NSObject
@property (nonatomic, weak) id<PIVideoDecodeDelegate> delegate;
+ (PIVideoDecode *)shared;
- (BOOL)updateSps:(NSData *)sps pps:(NSData *)pps;
- (void)decodeData:(NSData *)data completionHandle:(PIVideoDecodeCompletionHandle)completionHandle;
@end
