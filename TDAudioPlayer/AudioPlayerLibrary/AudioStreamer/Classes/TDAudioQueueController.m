//
//  TDAudioQueueController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/29/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import "TDAudioQueueController.h"

@implementation TDAudioQueueController

+ (void)playAudioQueue:(AudioQueueRef)audioQueue
{
    // change NULL to adjust for start time
    OSStatus err = AudioQueueStart(audioQueue, NULL);

    if (err) {
        NSLog(@"Error starting audio queue");
        return;
    }
}

+ (void)pauseAudioQueue:(AudioQueueRef)audioQueue
{
    OSStatus err = AudioQueuePause(audioQueue);

    if (err) {
        NSLog(@"Error pausing audio queue");
        return;
    }
}

+ (void)stopAudioQueue:(AudioQueueRef)audioQueue
{
    [self stopAudioQueue:audioQueue immediately:YES];
}

+ (void)finishAudioQueue:(AudioQueueRef)audioQueue
{
    [self stopAudioQueue:audioQueue immediately:NO];
}

+ (void)stopAudioQueue:(AudioQueueRef)audioQueue immediately:(BOOL)immediately
{
    OSStatus err = AudioQueueStop(audioQueue, immediately);

    if (err) {
        NSLog(@"Error stopping audio queue");
        return;
    }
}

@end
