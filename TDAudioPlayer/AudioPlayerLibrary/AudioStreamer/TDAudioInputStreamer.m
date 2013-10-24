//
//  TDAudioInputStreamer.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioInputStreamer.h"
#import "TDAudioFileStream.h"
#import "TDAudioStream.h"
#import "TDAudioQueue.h"
#import "TDAudioQueueBuffer.h"

static UInt32 const kAudioStreamReadMaxLength = 512;
static UInt32 const kAudioQueueBufferSize = 2048;
static UInt32 const kAudioQueueBufferCount = 16;
NSString *const TDAudioInputStreamerDidFinishNotification = @"TDAudioInputStreamerDidFinishNotification";
NSString *const TDAudioInputStreamerDidStartPlayingNotification = @"TDAudioInputStreamerDidStartPlayingNotification";

@interface TDAudioInputStreamer () <TDAudioStreamDelegate, TDAudioFileStreamDelegate, TDAudioQueueDelegate>

@property (strong, nonatomic) NSThread *audioStreamerThread;
@property (strong, nonatomic) NSCondition *waitForQueueCondition;
@property (assign, nonatomic) BOOL isPlaying;

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) TDAudioFileStream *audioFileStream;
@property (strong, nonatomic) TDAudioQueue *audioQueue;

@end

@implementation TDAudioInputStreamer

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    _audioStream = [[TDAudioStream alloc] initWithURL:url];
    _audioStream.delegate = self;

    return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    _audioStream = [[TDAudioStream alloc] initWithInputStream:inputStream];
    _audioStream.delegate = self;

    return self;
}

- (void)start
{
    NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]], @"Must be on main thread to start audio streaming");

    _audioStreamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startAudioStreamer) object:nil];
    [_audioStreamerThread setName:@"TDAudioStreamerThread"];
    [_audioStreamerThread start];
}

- (void)startAudioStreamer
{
    _waitForQueueCondition = [[NSCondition alloc] init];

    _audioFileStream = [[TDAudioFileStream alloc] init];
    _audioFileStream.delegate = self;

    self.isPlaying = YES;

    [self.audioStream open];

    while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

#pragma mark - Properties

- (NSUInteger)audioStreamReadMaxLength
{
    if (!_audioStreamReadMaxLength)
        _audioStreamReadMaxLength = kAudioStreamReadMaxLength;

    return _audioStreamReadMaxLength;
}

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
    if (event == TDAudioStreamEventHasData) {
        uint8_t bytes[self.audioQueueBufferSize];
        UInt32 length = [audioStream readData:bytes maxLength:(UInt32)self.audioStreamReadMaxLength];

        [self.audioFileStream parseData:bytes length:length];
    } else if (event == TDAudioStreamEventEnd) {
        // clean up
        self.isPlaying = NO;
        [self.audioQueue finish];
    }
}

#pragma mark - TDAudioFileStreamDelegate

- (void)audioFileStreamDidBecomeReady:(TDAudioFileStream *)audioFileStream
{
    NSUInteger bufferSize = audioFileStream.packetBufferSize;
    if (bufferSize == 0) bufferSize = self.audioQueueBufferSize;

    if (audioFileStream.magicCookieData == NULL) {
        _audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:(UInt32)self.audioQueueBufferCount bufferSize:bufferSize];
    } else {
        _audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:(UInt32)self.audioQueueBufferCount bufferSize:bufferSize magicCookieData:audioFileStream.magicCookieData magicCookieSize:audioFileStream.magicCookieLength];
    }

    _audioQueue.delegate = self;
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length
{
    // give data to free audio queues
    TDAudioQueueBuffer *audioQueueBuffer = [self.audioQueue nextFreeBufferWithWaitCondition:self.waitForQueueCondition];

    UInt32 offset = 0;
    do {
        UInt32 leftovers = (UInt32)[audioQueueBuffer fillWithData:data length:length offset:offset];

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

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length description:(AudioStreamPacketDescription)description
{
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

#pragma mark - TDAudioQueueDelegate

- (void)audioQueue:(TDAudioQueue *)audioQueue didFreeBuffer:(AudioQueueBufferRef)audioQueueBufferRef
{
    [self.waitForQueueCondition lock];
    [self.waitForQueueCondition signal];
    [self.waitForQueueCondition unlock];
}

- (void)audioQueueDidFinish:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyAudioInputStreamerDidFinish) withObject:nil waitUntilDone:NO];
}

- (void)audioQueueDidStartPlaying:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyAudioInputStreamerDidStartPlaying) withObject:nil waitUntilDone:NO];
}

- (void)notifyAudioInputStreamerDidFinish
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidFinishNotification object:nil];
}

- (void)notifyAudioInputStreamerDidStartPlaying
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidStartPlayingNotification object:nil];
}

#pragma mark - Public Methods

- (void)resume
{
    [self.audioQueue play];
}

- (void)pause
{
    [self.audioQueue pause];
}

- (void)stop
{
    [self.audioQueue stop];
}


#pragma mark - Cleanup

- (void)dealloc
{
    self.audioStream = nil;
    self.audioFileStream = nil;
    self.audioQueue = nil;
}

@end
