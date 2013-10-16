//
//  TDAudioInputStreamer.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import "TDAudioInputStreamer.h"
#import "TDAudioFileStream.h"
#import "TDAudioStream.h"
#import "TDAudioQueue.h"
#import "TDAudioQueueBuffer.h"

const UInt32 kAudioQueueBufferSize = 1024;
const UInt32 kAudioQueueBufferCount = 5;

@interface TDAudioInputStreamer () <TDAudioStreamDelegate, TDAudioFileStreamDelegate, TDAudioQueueDelegate>

@property (strong, nonatomic) NSThread *audioStreamerThread;
@property (strong, nonatomic) NSCondition *waitForQueueCondition;
@property (strong, nonatomic) NSObject *mutex;

@property (strong, atomic) TDAudioStream *audioStream;
@property (strong, atomic) TDAudioFileStream *audioFileStream;
@property (strong, atomic) TDAudioQueue *audioQueue;

@end

@implementation TDAudioInputStreamer

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    _audioStream = [[TDAudioStream alloc] initWithURL:url];
    _audioStream.delegate = self;
    _mutex = [[NSObject alloc] init];

    return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    _audioStream = [[TDAudioStream alloc] initWithInputStream:inputStream];
    _audioStream.delegate = self;
    _mutex = [[NSObject alloc] init];

    return self;
}

- (void)start
{
    NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]], @"Must be on main thread to start audio streaming");

    _audioStreamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startAudioStreamer) object:nil];
    [_audioStreamerThread start];
}

- (void)startAudioStreamer
{
    _waitForQueueCondition = [[NSCondition alloc] init];

    _audioFileStream = [[TDAudioFileStream alloc] init];
    _audioFileStream.delegate = self;

    [self.audioStream open];
}

#pragma mark - Properties

- (NSUInteger)audioQueueBufferSize
{
    if (!_audioQueueBufferSize)
        _audioQueueBufferSize = kAudioQueueBufferSize;

    return _audioQueueBufferSize;
}

- (NSUInteger)audioQueueBufferCount
{
    if (!_audioQueueBufferCount)
        _audioQueueBufferCount = kAudioQueueBufferCount;

    return _audioQueueBufferCount;
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    @synchronized(self.mutex) {
        if (event == TDAudioStreamEventHasData) {
            uint8_t bytes[self.audioQueueBufferSize];
            UInt32 length = [audioStream readData:bytes maxLength:512];

            [self.audioFileStream parseData:bytes length:length];
        }
    }
}

#pragma mark - TDAudioFileStreamDelegate

- (void)audioFileStreamDidBecomeReady:(TDAudioFileStream *)audioFileStream
{
    @synchronized(self.mutex) {
        NSUInteger bufferSize = audioFileStream.packetBufferSize;
        if (bufferSize == 0) bufferSize = self.audioQueueBufferSize;

        if (audioFileStream.magicCookieData == NULL) {
            _audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize];
        } else {
            _audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize magicCookieData:audioFileStream.magicCookieData magicCookieSize:audioFileStream.magicCookieLength];
        }

        _audioQueue.delegate = self;
    }
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length
{
    @synchronized(self.mutex) {
        // give data to free audio queues
        TDAudioQueueBuffer *audioQueueBuffer = [self.audioQueue nextFreeBufferWithWaitCondition:self.waitForQueueCondition];

        UInt32 offset = 0;
        do {
            NSInteger leftovers = [audioQueueBuffer fillWithData:data length:length offset:offset];

            if (leftovers != 0) {
                // enqueue
                [self.audioQueue enqueueAudioQueueBuffer:audioQueueBuffer];
            }

            if (leftovers <= 0) {
                break;
            } else {
                // hold onto bytes not filled
                offset = length - leftovers;
                audioQueueBuffer = [self.audioQueue nextFreeBufferWithWaitCondition:self.waitForQueueCondition];
            }
        } while (YES);
    }
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length description:(AudioStreamPacketDescription)description
{
    @synchronized(self.mutex) {
        // give data to free audio queues
        TDAudioQueueBuffer *audioQueueBuffer = [self.audioQueue nextFreeBufferWithWaitCondition:self.waitForQueueCondition];

        BOOL moreRoom = [audioQueueBuffer fillWithData:data length:length packetDescription:description];

        if (!moreRoom) {
            // enqueue
            [self.audioQueue enqueueAudioQueueBuffer:audioQueueBuffer];
            // get next buffer
            audioQueueBuffer = [self.audioQueue nextFreeBufferWithWaitCondition:self.waitForQueueCondition];
            [audioQueueBuffer fillWithData:data length:length packetDescription:description];
        }
    }
}

#pragma mark - TDAudioQueueDelegate

- (void)audioQueue:(TDAudioQueue *)audioQueue didFreeBuffer:(AudioQueueBufferRef)audioQueueBufferRef
{
    [self.waitForQueueCondition lock];
    [self.waitForQueueCondition signal];
    [self.waitForQueueCondition unlock];
}

@end
