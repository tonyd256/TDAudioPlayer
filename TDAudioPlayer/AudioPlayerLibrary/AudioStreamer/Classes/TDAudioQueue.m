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

static NSUInteger const TDAudioQueueStartMinimumBuffers = 8;

@interface TDAudioQueue ()

@property (assign, nonatomic) AudioQueueRef audioQueue;
@property (strong, nonatomic) TDAudioQueueBufferManager *bufferManager;
@property (strong, nonatomic) NSCondition *waitForFreeBufferCondition;
@property (assign, nonatomic) NSUInteger buffersToFillBeforeStart;

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)inAudioQueueBufferRef;

@end

void TDAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    TDAudioQueue *audioQueue = (__bridge TDAudioQueue *)inUserData;
    [audioQueue didFreeAudioQueueBuffer:inBuffer];
}

@implementation TDAudioQueue

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize
{
    self = [super init];
    if (!self) return nil;

    OSStatus err = AudioQueueNewOutput(&basicDescription, TDAudioQueueOutputCallback, (__bridge void *)self, NULL, NULL, 0, &_audioQueue);

    if (err) {
        NSLog(@"Error creating audio queue output");
        return nil;
    }

    self.bufferManager = [[TDAudioQueueBufferManager alloc] initWithAudioQueue:self.audioQueue size:bufferSize count:bufferCount];

    AudioQueueSetParameter(self.audioQueue, kAudioQueueParam_Volume, 1.0);

    self.waitForFreeBufferCondition = [[NSCondition alloc] init];
    self.state = TDAudioQueueStateBuffering;
    self.buffersToFillBeforeStart = TDAudioQueueStartMinimumBuffers;

    return self;
}

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize
{
    self = [self initWithBasicDescription:basicDescription bufferCount:bufferCount bufferSize:bufferSize];
    if (!self) return nil;

    AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_MagicCookie, magicCookieData, magicCookieSize);
    free(magicCookieData);

    return self;
}

#pragma mark - Audio Queue Events

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)inAudioQueueBufferRef
{
    [self.bufferManager freeAudioQueueBuffer:inAudioQueueBufferRef];

    // signal that a buffer is now free
    [self.waitForFreeBufferCondition lock];
    [self.waitForFreeBufferCondition signal];
    [self.waitForFreeBufferCondition unlock];

    if (self.state == TDAudioQueueStateStopped && ![self.bufferManager isProcessingAudioQueueBuffer]) {
        [self.delegate audioQueueDidFinishPlaying];
    }
}

#pragma mark - Public Methods

- (TDAudioQueueBuffer *)nextFreeBuffer
{
    // wait for a free buffer
    if (![self.bufferManager hasAvailableAudioQueueBuffer]) {
        [self.waitForFreeBufferCondition lock];
        [self.waitForFreeBufferCondition wait];
        [self.waitForFreeBufferCondition unlock];
    }

    TDAudioQueueBuffer *next = [self.bufferManager nextFreeBuffer];

    if (!next) return [self nextFreeBuffer];
    return next;
}

- (void)enqueue
{
    [self.bufferManager enqueueNextBufferOnAudioQueue:self.audioQueue];

    if (self.state == TDAudioQueueStateBuffering && --self.buffersToFillBeforeStart == 0) {
        AudioQueuePrime(self.audioQueue, 0, NULL);
        [self play];
        [self.delegate audioQueueDidStartPlaying];
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

#pragma mark - Cleanup

- (void)dealloc
{
    [self.bufferManager freeBufferMemoryFromAudioQueue:self.audioQueue];
    AudioQueueDispose(self.audioQueue, YES);
}

@end
