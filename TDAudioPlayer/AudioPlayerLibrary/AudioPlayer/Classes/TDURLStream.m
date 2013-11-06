//
//  TDURLStream.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/6/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDURLStream.h"
#import "TDAudioInputStreamer.h"

@interface TDURLStream ()

@property (strong, nonatomic) TDAudioInputStreamer *streamer;

@end

@implementation TDURLStream

#pragma mark - Initialization

+ (instancetype)streamWithURL:(NSURL *)url
{
    return [[TDURLStream alloc] initWithURL:url];
}

+ (instancetype)streamWithPath:(NSString *)path
{
    return [[TDURLStream alloc] initWithURL:[NSURL URLWithString:path]];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    self.streamer = [[TDAudioInputStreamer alloc] initWithURL:url];
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
