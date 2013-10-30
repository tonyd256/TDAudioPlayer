//
//  TDAudioQueueBufferManager.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/29/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import "TDAudioQueueBufferManager.h"
#import "TDAudioQueueBuffer.h"

@interface TDAudioQueueBufferManager ()

@property (assign, nonatomic) UInt32 bufferCount;
@property (assign, nonatomic) UInt32 bufferSize;
@property (strong, nonatomic) NSArray *audioQueueBuffers;
@property (strong, nonatomic) NSMutableArray *freeBuffers;

@end

@implementation TDAudioQueueBufferManager

- (instancetype)initWithAudioQueue:(AudioQueueRef)audioQueue size:(UInt32)size count:(UInt32)count
{
    self = [super init];
    if (!self) return nil;

    self.bufferCount = count;
    self.bufferSize = size;

    self.freeBuffers = [NSMutableArray arrayWithCapacity:self.bufferCount];
    NSMutableArray *audioqueuebuffers = [NSMutableArray arrayWithCapacity:self.bufferCount];

    // allocate the audio queue buffers
    for (NSUInteger i = 0; i < self.bufferCount; i++) {
        TDAudioQueueBuffer *buffer = [[TDAudioQueueBuffer alloc] initWithAudioQueue:audioQueue size:(UInt32)self.bufferSize];

        audioqueuebuffers[i] = buffer;
        self.freeBuffers[i] = @(i);
    }

    self.audioQueueBuffers = [audioqueuebuffers copy];

    return self;
}

#pragma mark - Public Methods

- (void)freeAudioQueueBuffer:(AudioQueueBufferRef)audioQueueBuffer
{
    // figure out which buffer was freed
    for (NSUInteger i = 0; i < self.bufferCount; i++) {
        if ([(TDAudioQueueBuffer *)self.audioQueueBuffers[i] isEqual:audioQueueBuffer]) {
            [(TDAudioQueueBuffer *)self.audioQueueBuffers[i] reset];
            [self.freeBuffers addObject:@(i)];
            break;
        }
    }

#if DEBUG
    if (self.freeBuffers.count > self.bufferCount >> 1) {
        NSLog(@"Free Buffers: %lu", (unsigned long)self.freeBuffers.count);
    }
#endif
}

- (TDAudioQueueBuffer *)nextFreeBuffer
{
    if (![self hasAvailableAudioQueueBuffer]) return nil;
    return self.audioQueueBuffers[[[self.freeBuffers firstObject] integerValue]];
}

- (void)enqueueNextBufferOnAudioQueue:(AudioQueueRef)audioQueue
{
    NSInteger nextBufferIndex = [[self.freeBuffers firstObject] integerValue];
    [self.freeBuffers removeObjectAtIndex:0];

    TDAudioQueueBuffer *nextBuffer = self.audioQueueBuffers[nextBufferIndex];
    [nextBuffer enqueueWithAudioQueue:audioQueue];
}

- (BOOL)hasAvailableAudioQueueBuffer
{
    return self.freeBuffers.count > 0;
}

- (BOOL)isProcessingAudioQueueBuffer
{
    return self.freeBuffers.count != self.bufferCount;
}

#pragma mark - Cleanup

- (void)freeBufferMemoryFromAudioQueue:(AudioQueueRef)audioQueue
{
    for (NSUInteger i = 0; i < self.audioQueueBuffers.count; i++) {
        [(TDAudioQueueBuffer *)self.audioQueueBuffers[i] freeFromAudioQueue:audioQueue];
    }
}

@end
