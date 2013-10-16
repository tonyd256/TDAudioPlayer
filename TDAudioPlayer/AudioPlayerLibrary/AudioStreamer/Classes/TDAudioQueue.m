//
//  TDAudioQueue.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import "TDAudioQueue.h"
#import "TDAudioQueueBuffer.h"

@interface TDAudioQueue ()

@property (assign, atomic) AudioQueueRef audioQueue;
@property (assign, nonatomic) NSUInteger bufferCount;
@property (assign, nonatomic) NSUInteger bufferSize;
@property (strong, nonatomic) NSArray *audioQueueBuffers;
@property (strong, atomic) NSMutableArray *freeBuffers;

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)inAudioQueueBufferRef;
- (void)didChangeProperty:(AudioQueuePropertyID)inPropertyID;

@end

void TDAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    TDAudioQueue *audioQueue = (__bridge TDAudioQueue *)inUserData;
    [audioQueue didFreeAudioQueueBuffer:inBuffer];
}

void TDAudioQueuePropertyChangedCallback(void *inUserData, AudioQueueRef inAudioQueueRef, AudioQueuePropertyID inPropertyID)
{
    TDAudioQueue *audioQueue = (__bridge TDAudioQueue *)inUserData;
    [audioQueue didChangeProperty:inPropertyID];
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

    err = AudioQueueAddPropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, TDAudioQueuePropertyChangedCallback, (__bridge void *)self);

    if (err) {
        NSLog(@"Error creating audio queue is running listener");
        return nil;
    }

    _bufferCount = bufferCount;
    _bufferSize = bufferSize;

    _freeBuffers = [NSMutableArray array];

    NSMutableArray *audioqueuebuffers = [NSMutableArray arrayWithCapacity:_bufferCount];

    // allocate the audio queue buffers
    for (NSUInteger i = 0; i < _bufferCount; i++) {
        TDAudioQueueBuffer *buffer = [[TDAudioQueueBuffer alloc] initWithAudioQueue:_audioQueue size:_bufferSize];

        audioqueuebuffers[i] = buffer;
        [self.freeBuffers addObject:@(i)];
    }

    _audioQueueBuffers = [audioqueuebuffers copy];

    _state = TDAudioQueueStateBuffering;

    return self;
}

- (instancetype)initWithBasicDescription:(AudioStreamBasicDescription)basicDescription bufferCount:(UInt32)bufferCount bufferSize:(UInt32)bufferSize magicCookieData:(void *)magicCookieData magicCookieSize:(UInt32)magicCookieSize
{
    self = [self initWithBasicDescription:basicDescription bufferCount:bufferCount bufferSize:bufferSize];
    if (!self) return nil;

    AudioQueueSetProperty(_audioQueue, kAudioQueueProperty_MagicCookie, magicCookieData, magicCookieSize);
    free(magicCookieData);

    return self;
}

#pragma mark - Audio Queue Events

- (void)didFreeAudioQueueBuffer:(AudioQueueBufferRef)inAudioQueueBufferRef
{
    // figure out which buffer was freed
    for (NSUInteger i = 0; i < self.bufferCount; i++) {
        if ([(TDAudioQueueBuffer *)self.audioQueueBuffers[i] isEqual:inAudioQueueBufferRef]) {
            [(TDAudioQueueBuffer *)self.audioQueueBuffers[i] reset];
            [self.freeBuffers addObject:@(i)];
            break;
        }
    }

    // signal that a buffer is now free
    if ([self.delegate respondsToSelector:@selector(audioQueue:didFreeBuffer:)]) {
        [self.delegate audioQueue:self didFreeBuffer:inAudioQueueBufferRef];
    }
}

- (void)didChangeProperty:(AudioQueuePropertyID)inPropertyID
{
    if (inPropertyID == kAudioQueueProperty_IsRunning) {
        UInt32 isRunnning = 0;
        UInt32 size = sizeof(UInt32);
        AudioQueueGetProperty(self.audioQueue, inPropertyID, &isRunnning, &size);

        if (isRunnning == 0) {
            self.state = TDAudioQueueStateStopped;
        } else {
            self.state = TDAudioQueueStatePlaying;
        }
    }
}

#pragma mark - Public Methods

- (TDAudioQueueBuffer *)nextFreeBufferWithWaitCondition:(NSCondition *)waitCondition
{
    if (self.freeBuffers.count == 0) {
        if (self.state == TDAudioQueueStateBuffering) {
            [self play];
        }
        [waitCondition lock];
        [waitCondition wait];
        [waitCondition unlock];
    }

    NSNumber *index = [self.freeBuffers firstObject];

    return self.audioQueueBuffers[[index integerValue]];
}

- (void)enqueueAudioQueueBuffer:(TDAudioQueueBuffer *)audioQueueBuffer
{
    [self.freeBuffers removeObjectAtIndex:0];

    [audioQueueBuffer enqueueWithAudioQueue:self.audioQueue];
}

#pragma mark - Audio Queue Controls

- (void)play
{
    if (self.state == TDAudioQueueStatePlaying) return;

    // change NULL to adjust for start time
    OSStatus err = AudioQueueStart(self.audioQueue, NULL);

    if (err) {
        NSLog(@"Error starting audio queue");
        return;
    }

    self.state = TDAudioQueueStateWaitingToPlay;
}

- (void)pause
{
    if (self.state == TDAudioQueueStatePaused) return;

    OSStatus err = AudioQueuePause(self.audioQueue);

    if (err) {
        NSLog(@"Error pausing audio queue");
        return;
    }

    self.state = TDAudioQueueStatePaused;
}

- (void)stop
{
    if (self.state == TDAudioQueueStateStopped) return;

    OSStatus err = AudioQueueStop(self.audioQueue, YES);

    if (err) {
        NSLog(@"Error stopping audio queue");
        return;
    }

    self.state = TDAudioQueueStateStopped;
}

@end
