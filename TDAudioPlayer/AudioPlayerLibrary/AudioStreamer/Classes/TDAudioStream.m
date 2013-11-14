//
//  TDAudioStream.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioStream.h"

@interface TDAudioStream () <NSStreamDelegate>

@property (strong, nonatomic) NSInputStream *stream;

@end

@implementation TDAudioStream

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    self.stream = inputStream;

    return self;
}

- (void)open
{
    self.stream.delegate = self;
    [self.stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    return [self.stream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasBytesAvailable) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventHasData];
    } else if (eventCode == NSStreamEventEndEncountered) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventEnd];
    } else if (eventCode == NSStreamEventErrorOccurred) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventError];
    }
}

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return (UInt32)[self.stream read:data maxLength:maxLength];
}

- (void)dealloc
{
    [self.stream close];
    self.stream.delegate = nil;
    [self.stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

@end
