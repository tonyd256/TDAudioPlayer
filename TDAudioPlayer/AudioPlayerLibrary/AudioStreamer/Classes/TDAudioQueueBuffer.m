//
//  TDAudioQueueBuffer.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/11/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import "TDAudioQueueBuffer.h"

const NSUInteger TDMaxPacketDescriptions = 512;

@interface TDAudioQueueBuffer ()

@property (assign, atomic) AudioQueueBufferRef audioQueueBuffer;
@property (assign, atomic) NSUInteger size;
@property (assign, atomic) NSUInteger fillPosition;
@property (assign, atomic) AudioStreamPacketDescription *packetDescriptions;
@property (assign, atomic) NSUInteger numberOfPacketDescriptions;

@end

@implementation TDAudioQueueBuffer

- (instancetype)initWithAudioQueue:(AudioQueueRef)audioQueue size:(UInt32)size
{
    self = [super init];
    if (!self) return nil;

    _size = size;
    _fillPosition = 0;
    _packetDescriptions = malloc(sizeof(AudioStreamPacketDescription) * TDMaxPacketDescriptions);
    _numberOfPacketDescriptions = 0;

    OSStatus err = AudioQueueAllocateBuffer(audioQueue, _size, &_audioQueueBuffer);

    if (err) {
        NSLog(@"Error allocating audio queue buffer");
        return nil;
    }

    return self;
}

- (NSInteger)fillWithData:(const void *)data length:(UInt32)length offset:(UInt32)offset
{
    // fill to brim since no packets
    if (self.fillPosition + length <= self.size) {
        memcpy((char *)(self.audioQueueBuffer->mAudioData + self.fillPosition), (const char *)(data + offset), length);
        self.fillPosition += length;
    } else {
        NSUInteger availableSpace = self.size - self.fillPosition;
        memcpy((char *)(self.audioQueueBuffer->mAudioData + self.fillPosition), (const char *)data, availableSpace);
        self.fillPosition = self.size;
        return length - availableSpace;
    }

    if (self.fillPosition == self.size) {
        return -1;
    }

    return 0;
}

- (BOOL)fillWithData:(const void *)data length:(UInt32)length packetDescription:(AudioStreamPacketDescription)packetDescription
{
    if (self.fillPosition + packetDescription.mDataByteSize > self.size || self.numberOfPacketDescriptions == TDMaxPacketDescriptions) return NO;

    memcpy((char *)(self.audioQueueBuffer->mAudioData + self.fillPosition), (const char *)(data + packetDescription.mStartOffset), packetDescription.mDataByteSize);

    self.packetDescriptions[self.numberOfPacketDescriptions] = packetDescription;
    self.packetDescriptions[self.numberOfPacketDescriptions].mStartOffset = self.fillPosition;
    self.numberOfPacketDescriptions++;

    self.fillPosition += packetDescription.mDataByteSize;

    return YES;
}

- (void)enqueueWithAudioQueue:(AudioQueueRef)audioQueue
{
    self.audioQueueBuffer->mAudioDataByteSize = self.fillPosition;
    OSStatus err = AudioQueueEnqueueBuffer(audioQueue, self.audioQueueBuffer, self.numberOfPacketDescriptions, self.packetDescriptions);

    if (err) {
        NSLog(@"Error enqueueing audio buffer");
    }
}

- (void)reset
{
    self.fillPosition = 0;
    self.numberOfPacketDescriptions = 0;
}

- (BOOL)isEqual:(AudioQueueBufferRef)audioQueueBuffer
{
    return audioQueueBuffer == self.audioQueueBuffer;
}

@end
