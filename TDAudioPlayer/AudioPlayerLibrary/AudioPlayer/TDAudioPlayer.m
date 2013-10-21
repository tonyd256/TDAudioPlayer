//
//  TDAudioPlayer.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TDAudioPlayer.h"
#import "TDPlaylist.h"
#import "TDTrack.h"
#import "TDAudioInputStreamer.h"

NSString *const TDAudioPlayerDidChangeTracksNotification = @"TDAudioPlayerDidChangeTracksNotification";

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
    });
    return player;
}

- (instancetype)init
{
    self = [super self];
    if (!self) return nil;

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setInputGain:1.0 error:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidFinish) name:TDAudioInputStreamerDidFinishNotification object:nil];

    return self;
}

#pragma mark - Properties

- (TDPlaylist *)loadedPlaylist
{
    return self.playlist;
}

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

    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidChangeTracksNotification object:nil];

    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:track.albumArtLarge]]]];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{MPMediaItemPropertyTitle: track.title,
                                                              MPMediaItemPropertyArtist: track.artist,
                                                              MPMediaItemPropertyArtwork: artwork,
                                                              MPNowPlayingInfoPropertyElapsedPlaybackTime: @0,
                                                              MPNowPlayingInfoPropertyPlaybackQueueCount: @(self.playlist.trackList.count),
                                                              MPNowPlayingInfoPropertyPlaybackQueueIndex: @(self.playlist.currentTrackIndex)};
}

- (void)loadPlaylist:(TDPlaylist *)playlist
{
    self.playlist = playlist;
    [self loadTrack:[self.playlist currentTrack]];
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

- (void)playNextTrack
{
    TDTrack *track = [self.playlist nextTrack];

    if (!track) return;

    [self stop];

    _playing = NO;
    self.streamer = nil;

    [self loadTrack:track];
    [self play];
}

- (void)playPreviousTrack
{
    TDTrack *track = [self.playlist previousTrack];

    if (!track) return;

    [self stop];

    _playing = NO;
    self.streamer = nil;

    [self loadTrack:track];
    [self play];

}

#pragma mark - Notification Handlers

- (void)audioSessionDidInterrupt:(NSNotification *)notification
{
    NSUInteger type = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
    }
}

- (void)trackDidFinish
{
    [self playNextTrack];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
