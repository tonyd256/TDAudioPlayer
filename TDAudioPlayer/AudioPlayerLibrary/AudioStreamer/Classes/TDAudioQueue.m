//
//  TDAudioQueue.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioQueue.h"
#import "TDAudioQueueBuffer.h"
#import "TDAudioQueueController.h"
#import "TDAudioQueueBufferManager.h"
#import "TDAudioPlayerConstants.h"

@interface TDAudioQueue ()

@property (assign, nonatomic) AudioQueueRef audioQueue;
@property (strong, nonatomic) TDAudioQueueBufferManager *bufferManager;
@property (strong, nonatomic) NSCondition *waitForFreeBufferCondition;
@property (assign, nonatomic) NSUInteger buffersToFillBeforeStart;
@property (assign, nonatomic) NSUInteger buffersToFillAfterStart;
@property (assign, nonatomic) NSUInteger bufferCount;
@property (assign, nonatomic) NSUInteger bufferUnderrunThreshold;
@property (assign, nonatomic) BOOL isFirstStart;

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)audioQueueBuffer;

@end

void TDAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAudioQueue, AudioQueueBufferRef inAudioQueueBuffer)
{
    TDAudioQueue *audioQueue = (__bridge TDAudioQueue *)inUserData;
    [audioQueue didFreeAudioQueueBuffer:inAudioQueueBuffer];
}

@implementation TDAudioQueue

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize
{
    return [self initWithBasicDescription:basicDescription bufferCount:bufferCount bufferSize:bufferSize magicCookieData:magicCookieData magicCookieSize:magicCookieSize buffersToFillBeforeStart:(3 * bufferCount / 4) buffersToFillAfterStart:(bufferCount / 4) bufferUnderrunThreashold:(bufferCount / 4)];
}

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize buffersToFillBeforeStart:(UInt32)buffersToFillBeforeStart buffersToFillAfterStart:(UInt32)buffersToFillAfterStart bufferUnderrunThreashold:(UInt32)bufferUnderrunThreshold
{
    self = [self init];
    if (!self) return nil;

    OSStatus err = AudioQueueNewOutput(&basicDescription, TDAudioQueueOutputCallback, (__bridge void *)self, NULL, NULL, 0, &_audioQueue);

    if (err) return nil;

    self.bufferManager = [[TDAudioQueueBufferManager alloc] initWithAudioQueue:self.audioQueue size:bufferSize count:bufferCount];

    AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_MagicCookie, magicCookieData, magicCookieSize);

    AudioQueueSetParameter(self.audioQueue, kAudioQueueParam_Volume, 1.0);

    self.waitForFreeBufferCondition = [[NSCondition alloc] init];
    self.state = TDAudioQueueStateBuffering;
    self.bufferCount = bufferCount;
    self.buffersToFillBeforeStart = buffersToFillBeforeStart;
    self.buffersToFillAfterStart = buffersToFillAfterStart;
    self.bufferUnderrunThreshold = bufferUnderrunThreshold;
    self.isFirstStart = YES;

    return self;
}

#pragma mark - Audio Queue Events

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)audioQueueBuffer
{
    [self.bufferManager freeAudioQueueBuffer:audioQueueBuffer];

    [self.waitForFreeBufferCondition lock];
    [self.waitForFreeBufferCondition signal];
    [self.waitForFreeBufferCondition unlock];

    if (self.state == TDAudioQueueStateStopped && ![self.bufferManager isProcessingAudioQueueBuffer]) {
        [self.delegate audioQueueDidFinishPlaying:self];
    }
    else if (self.state == TDAudioQueueStatePlaying) {
        NSUInteger freeBuffersCount = [self.bufferManager freeBuffersCount];
        
        if (self.bufferCount - freeBuffersCount <= self.bufferUnderrunThreshold) {
            self.state = TDAudioQueueStateBuffering;
            [self.delegate audioQueueBuffering:self];
        }
    }
}

#pragma mark - Public Methods

- (TDAudioQueueBuffer *)nextFreeBuffer
{
    if (![self.bufferManager hasAvailableAudioQueueBuffer]) {
        [self.waitForFreeBufferCondition lock];
        [self.waitForFreeBufferCondition wait];
        [self.waitForFreeBufferCondition unlock];
    }

    TDAudioQueueBuffer *nextBuffer = [self.bufferManager nextFreeBuffer];

    if (!nextBuffer) return [self nextFreeBuffer];
    return nextBuffer;
}

- (void)enqueue
{
    [self.bufferManager enqueueNextBufferOnAudioQueue:self.audioQueue];

    if (self.state == TDAudioQueueStateBuffering) {
        NSUInteger freeBuffersCount = [self.bufferManager freeBuffersCount];
        
        if (self.isFirstStart) {
            if (self.bufferCount - freeBuffersCount >= self.buffersToFillBeforeStart) {
                if (self.isFirstStart) {
                    self.isFirstStart = NO;
                    
                    UInt32 numberOfFramesPrepared = 0;
                    
                    AudioQueuePrime(self.audioQueue, 2, &numberOfFramesPrepared);
                    [self play];
                }
                else {
                    self.state = TDAudioQueueStatePlaying;
                }
                
                [self.delegate audioQueueDidStartPlaying:self];
            }
        }
        else {
            if (self.bufferCount - freeBuffersCount >= self.buffersToFillAfterStart) {
                [self play];
                [self.delegate audioQueueDidStartPlaying:self];
            }
            else {
                [TDAudioQueueController pauseAudioQueue:self.audioQueue];
            }
        }
    }
}

#pragma mark - Audio Queue Controls

- (void)play
{
    if (self.state == TDAudioQueueStatePlaying) return;

    [TDAudioQueueController playAudioQueue:self.audioQueue];
    self.state = TDAudioQueueStatePlaying;
}

- (void)pause
{
    if (self.state == TDAudioQueueStatePaused) return;

    [TDAudioQueueController pauseAudioQueue:self.audioQueue];
    self.state = TDAudioQueueStatePaused;
}

- (void)stop
{
    if (self.state == TDAudioQueueStateStopped) return;

    [TDAudioQueueController stopAudioQueue:self.audioQueue];
    self.state = TDAudioQueueStateStopped;
}

- (void)finish
{
    if (self.state == TDAudioQueueStateStopped) return;

    [TDAudioQueueController finishAudioQueue:self.audioQueue];
    self.state = TDAudioQueueStateStopped;
}

- (void)setVolume:(CGFloat)volume {
    [TDAudioQueueController setVolume:volume audioQueue:self.audioQueue];
}


#pragma mark - Cleanup

- (void)dealloc
{
    [self.bufferManager freeBufferMemoryFromAudioQueue:self.audioQueue];
    AudioQueueDispose(self.audioQueue, NO);
}

@end
