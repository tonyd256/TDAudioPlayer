//
//  TDInputStream.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/6/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDInputStream.h"
#import "TDAudioInputStreamer.h"

@interface TDInputStream ()

@property (strong, nonatomic) TDAudioInputStreamer *streamer;

@end

@implementation TDInputStream

#pragma mark - Initialization

+ (instancetype)streamWithInputStream:(NSInputStream *)inputStream
{
    return [[TDInputStream alloc] initWithInputStream:inputStream];
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    self.streamer = [[TDAudioInputStreamer alloc] initWithInputStream:inputStream];
    if (!self.streamer) return nil;

    return self;
}

#pragma mark - TDStream Protocol

- (void)start
{
    [self.streamer start];
}

- (void)resume
{
    [self.streamer resume];
}

- (void)pause
{
    [self.streamer pause];
}

- (void)stop
{
    [self.streamer stop];
}

@end
