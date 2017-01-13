//
//  TDAudioQueue.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, TDAudioQueueState) {
    TDAudioQueueStateBuffering,
    TDAudioQueueStateStopped,
    TDAudioQueueStatePaused,
    TDAudioQueueStatePlaying
};

@class TDAudioQueue;

@protocol TDAudioQueueDelegate <NSObject>

- (void)audioQueueDidFinishPlaying:(TDAudioQueue *)audioQueue;
- (void)audioQueueDidStartPlaying:(TDAudioQueue *)audioQueue;
- (void)audioQueueBuffering:(TDAudioQueue *)audioQueue;

@end

@class TDAudioQueueBuffer;

@interface TDAudioQueue : NSObject

@property (assign, nonatomic) TDAudioQueueState state;
@property (assign, nonatomic) id<TDAudioQueueDelegate> delegate;

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize;

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize buffersToFillBeforeStart:(UInt32)buffersToFillBeforeStart buffersToFillAfterStart:(UInt32)buffersToFillAfterStart bufferUnderrunThreashold:(UInt32)bufferUnderrunThreshold;

- (TDAudioQueueBuffer *)nextFreeBuffer;
- (void)enqueue;

- (void)play;
- (void)pause;
- (void)stop;
- (void)finish;
- (void)setVolume:(CGFloat)volume;

@end
