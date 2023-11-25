//
//  TDAudioQueueController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/29/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioQueueController.h"

@implementation TDAudioQueueController

+ (OSStatus)playAudioQueue:(AudioQueueRef)audioQueue
{
    return AudioQueueStart(audioQueue, NULL);
}

+ (OSStatus)pauseAudioQueue:(AudioQueueRef)audioQueue
{
    return AudioQueuePause(audioQueue);
}

+ (OSStatus)stopAudioQueue:(AudioQueueRef)audioQueue
{
    return [self stopAudioQueue:audioQueue immediately:YES];
}

+ (OSStatus)finishAudioQueue:(AudioQueueRef)audioQueue
{
    return [self stopAudioQueue:audioQueue immediately:NO];
}

+ (OSStatus)stopAudioQueue:(AudioQueueRef)audioQueue immediately:(BOOL)immediately
{
    OSStatus status = AudioQueueStop(audioQueue, immediately);
    return status;
}

+ (OSStatus)resetAudioQueue:(AudioQueueRef)audioQueue
{
    OSStatus status = AudioQueueReset(audioQueue);
    return status;
}

+ (OSStatus)setVolume:(CGFloat)volume audioQueue:(AudioQueueRef)audioQueue {
    return AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, volume);
}

@end
