//
//  PIImageInfo.m
//  playin
//
//  Created by lijunge on 2019/5/5.
//  Copyright © 2019 A. All rights reserved.
//

#import "PIImageInfo.h"

@implementation PIImageInfo
+ (UIImage*)PlayInAudioOnImage{
    return [self PlayInImageWithBase64Data:playin_audio_on_string];
}

+ (UIImage*)PlayInAudioMuteImage{
    return [self PlayInImageWithBase64Data:playin_audio_mute_string];
}

+ (UIImage*)PlayInCancelImage{
    return [self PlayInImageWithBase64Data:playin_cancel_image_string];
}
+ (UIImage*)PlayInAdIcon{
    return [self PlayInImageWithBase64Data:playin_adIcon_string];
}
+ (UIImage*)PlayInVideoSkipImage{
    return [self PlayInImageWithBase64Data:playin_video_skip];
}

+ (UIImage*)PlayInImageWithBase64Data:(NSString*)base64Str{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:base64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [[UIImage alloc]initWithData:data];
}
@end
