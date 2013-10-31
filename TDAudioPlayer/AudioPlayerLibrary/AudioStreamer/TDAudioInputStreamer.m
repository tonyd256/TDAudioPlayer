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
#import "TDAudioQueueFiller.h"

static UInt32 const kTDAudioStreamReadMaxLength = 512;
static UInt32 const kTDAudioQueueBufferSize = 2048;
static UInt32 const kTDAudioQueueBufferCount = 16;

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
    if (!self.audioStream) return nil;

    return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    self.audioStream = [[TDAudioStream alloc] initWithInputStream:inputStream];
    if (!self.audioStream) return nil;

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

    if (!self.audioFileStream)
        return [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidFinishPlayingNotification object:nil];

    self.audioFileStream.delegate = self;

    self.audioStream.delegate = self;
    [self.audioStream open];

    self.isPlaying = YES;

    while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

#pragma mark - Properties

- (UInt32)audioStreamReadMaxLength
{
    if (!_audioStreamReadMaxLength)
        _audioStreamReadMaxLength = kTDAudioStreamReadMaxLength;

    return _audioStreamReadMaxLength;
}

- (UInt32)audioQueueBufferSize
{
    if (!_audioQueueBufferSize)
        _audioQueueBufferSize = kTDAudioQueueBufferSize;

    return _audioQueueBufferSize;
}

- (UInt32)audioQueueBufferCount
{
    if (!_audioQueueBufferCount)
        _audioQueueBufferCount = kTDAudioQueueBufferCount;

    return _audioQueueBufferCount;
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventHasData: {
            uint8_t bytes[self.audioQueueBufferSize];
            UInt32 length = [audioStream readData:bytes maxLength:self.audioStreamReadMaxLength];
            [self.audioFileStream parseData:bytes length:length];
            break;
        }

        case TDAudioStreamEventEnd:
            self.isPlaying = NO;
            [self.audioQueue finish];
            break;

        case TDAudioStreamEventError:
            [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidFinishPlayingNotification object:nil];
            break;

        default:
            break;
    }
}

#pragma mark - TDAudioFileStreamDelegate

- (void)audioFileStreamDidBecomeReady:(TDAudioFileStream *)audioFileStream
{
    UInt32 bufferSize = audioFileStream.packetBufferSize ? audioFileStream.packetBufferSize : self.audioQueueBufferSize;

    self.audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize magicCookieData:audioFileStream.magicCookieData magicCookieSize:audioFileStream.magicCookieLength];

    self.audioQueue.delegate = self;
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveError:(OSStatus)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioInputStreamerDidFinishPlayingNotification object:nil];
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length
{
    [TDAudioQueueFiller fillAudioQueue:self.audioQueue withData:data length:length offset:0];
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length packetDescription:(AudioStreamPacketDescription)packetDescription
{
    [TDAudioQueueFiller fillAudioQueue:self.audioQueue withData:data length:length packetDescription:packetDescription];
}

#pragma mark - TDAudioQueueDelegate

- (void)audioQueueDidFinishPlaying:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyMainThread:) withObject:TDAudioInputStreamerDidFinishPlayingNotification waitUntilDone:NO];
}

- (void)audioQueueDidStartPlaying:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyMainThread:) withObject:TDAudioInputStreamerDidStartPlayingNotification waitUntilDone:NO];
}

- (void)notifyMainThread:(NSString *)notificationName
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
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

@end
