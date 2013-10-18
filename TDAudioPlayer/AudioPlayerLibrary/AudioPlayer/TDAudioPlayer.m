//
//  TDAudioPlayer.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import "TDAudioPlayer.h"
#import "TDPlaylist.h"
#import "TDTrack.h"
#import "TDAudioInputStreamer.h"

@interface TDAudioPlayer ()

@property (strong, nonatomic) TDTrack *currentTrack;
@property (strong, nonatomic) TDPlaylist *playlist;
@property (strong, nonatomic) TDAudioInputStreamer *streamer;

@property (assign, nonatomic) BOOL playing;
@property (assign, nonatomic) BOOL paused;

@end

@implementation TDAudioPlayer

+ (instancetype)sharedAudioPlayer
{
    static TDAudioPlayer *player;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[TDAudioPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:player selector:@selector(trackDidFinish) name:TDAudioInputStreamerDidFinishNotification object:nil];
    });
    return player;
}

#pragma mark - Properties

- (TDTrack *)currentTrack
{
    return _currentTrack;
}

- (BOOL)isPlaying
{
    return _playing;
}

- (BOOL)isPaused
{
    return _paused;
}

#pragma mark - Public Methods

- (void)loadTrack:(TDTrack *)track
{
    self.currentTrack = track;
}

- (void)loadPlaylist:(TDPlaylist *)playlist
{
    self.playlist = playlist;
}

- (void)play
{
    if (!self.currentTrack || self.playing) return;

    if (!_streamer) {
        _streamer = [[TDAudioInputStreamer alloc] initWithURL:self.currentTrack.source];
        [_streamer start];
    } else {
        [self.streamer resume];
    }

    _playing = YES;
    _paused = NO;
}

- (void)pause
{
    if (!self.currentTrack || self.paused) return;

    [self.streamer pause];
    _playing = NO;
    _paused = YES;
}

- (void)stop
{
    if (!self.currentTrack || self.streamer == nil) return;

    [self.streamer stop];
    self.streamer = nil;
    _playing = NO;
    _paused = NO;
}

#pragma mark - Notification Handlers

- (void)trackDidFinish
{
    _playing = NO;
    self.streamer = nil;

    TDTrack *track = [self.playlist nextTrack];

    if (track) {
        [self loadTrack:track];
        [self play];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
