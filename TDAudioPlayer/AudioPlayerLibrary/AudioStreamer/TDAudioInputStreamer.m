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
NSString *const TDAudioInputStreamerDidFinishPlayingNotification = @"TDAudioInputStreamerDidFinishPlayingNotification";
NSString *const TDAudioInputStreamerDidStartPlayingNotification = @"TDAudioInputStreamerDidStartPlayingNotification";

@interface TDAudioInputStreamer () <TDAudioStreamDelegate, TDAudioFileStreamDelegate, TDAudioQueueDelegate>

@property (strong, nonatomic) NSThread *audioStreamerThread;
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

    self.audioStream = [[TDAudioStream alloc] initWithURL:url];
    self.audioStream.delegate = self;

    return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    self.audioStream = [[TDAudioStream alloc] initWithInputStream:inputStream];
    self.audioStream.delegate = self;

    return self;
}

- (void)start
{
    NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]], @"Must be on main thread to start audio streaming");

    self.audioStreamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startAudioStreamer) object:nil];
    [self.audioStreamerThread setName:@"TDAudioStreamerThread"];
    [self.audioStreamerThread start];
}

- (void)startAudioStreamer
{
    self.audioFileStream = [[TDAudioFileStream alloc] init];
    self.audioFileStream.delegate = self;

    self.isPlaying = YES;

    [self.audioStream open];

    while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

#pragma mark - Properties

- (UInt32)audioStreamReadMaxLength
{
    if (!_audioStreamReadMaxLength)
        _audioStreamReadMaxLength = kAudioStreamReadMaxLength;

    return _audioStreamReadMaxLength;
}

- (UInt32)audioQueueBufferSize
{
    if (!_audioQueueBufferSize)
        _audioQueueBufferSize = kAudioQueueBufferSize;

    return _audioQueueBufferSize;
}

- (UInt32)audioQueueBufferCount
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
        UInt32 length = [audioStream readData:bytes maxLength:self.audioStreamReadMaxLength];

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
    UInt32 bufferSize = audioFileStream.packetBufferSize;
    if (bufferSize == 0) bufferSize = self.audioQueueBufferSize;

    if (audioFileStream.magicCookieData == NULL) {
        self.audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize];
    } else {
        self.audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize magicCookieData:audioFileStream.magicCookieData magicCookieSize:audioFileStream.magicCookieLength];
    }

    self.audioQueue.delegate = self;
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length
{
    // give data to free audio queues
    TDAudioQueueBuffer *audioQueueBuffer = [self.audioQueue nextFreeBuffer];

    UInt32 offset = 0;
    do {
        NSInteger leftovers = [audioQueueBuffer fillWithData:data length:length offset:offset];

        if (leftovers != 0) {
            // enqueue
            [self.audioQueue enqueue];
        }

        if (leftovers <= 0) {
            break;
        } else {
            // hold onto bytes not filled
            offset = length - (UInt32)leftovers;
            audioQueueBuffer = [self.audioQueue nextFreeBuffer];
        }
    } while (YES);
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length description:(AudioStreamPacketDescription)description
{
    // give data to free audio queues
    TDAudioQueueBuffer *audioQueueBuffer = [self.audioQueue nextFreeBuffer];

    BOOL moreRoom = [audioQueueBuffer fillWithData:data length:length packetDescription:description];

    if (!moreRoom) {
        // enqueue
        [self.audioQueue enqueue];
        // get next buffer
        audioQueueBuffer = [self.audioQueue nextFreeBuffer];
        [audioQueueBuffer fillWithData:data length:length packetDescription:description];
    }
}

#pragma mark - TDAudioQueueDelegate

- (void)audioQueueDidFinishPlaying
{
    [self performSelectorOnMainThread:@selector(notifyAudioInputStreamerDidFinishPlaying) withObject:nil waitUntilDone:NO];
}

- (void)audioQueueDidStartPlaying
{
    [self performSelectorOnMainThread:@selector(notifyAudioInputStreamerDidStartPlaying) withObject:nil waitUntilDone:NO];
}

- (void)notifyAudioInputStreamerDidFinishPlaying
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidFinishPlayingNotification object:nil];
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
    self.isPlaying = NO;
    [self.audioQueue stop];
}


#pragma mark - Cleanup

- (void)dealloc
{
    _audioStream = nil;
    _audioFileStream = nil;
    _audioQueue = nil;
}

@end
