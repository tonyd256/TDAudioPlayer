//
//  TDAudioQueueController.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/29/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface TDAudioQueueController : NSObject

+ (void)playAudioQueue:(AudioQueueRef)audioQueue;
+ (void)pauseAudioQueue:(AudioQueueRef)audioQueue;
+ (void)stopAudioQueue:(AudioQueueRef)audioQueue;
+ (void)finishAudioQueue:(AudioQueueRef)audioQueue;

@end
