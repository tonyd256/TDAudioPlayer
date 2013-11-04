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
#import "TDTrack.h"
#import "TDAudioInputStreamer.h"

NSString *const TDAudioPlayerDidChangeTracksNotification = @"TDAudioPlayerDidChangeTracksNotification";
NSString *const TDAudioPlayerDidForcePauseNotification = @"TDAudioPlayerDidForcePauseNotification";

@interface TDAudioPlayer ()

@property (strong, nonatomic) id <TDTrack> currentTrack;
@property (assign, nonatomic) NSUInteger currentTrackIndex;
@property (strong, nonatomic) NSArray *playlist;
@property (strong, nonatomic) TDAudioInputStreamer *streamer;

@property (assign, nonatomic) BOOL playing;
@property (assign, nonatomic) BOOL paused;

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSUInteger elapsedTime;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChangeRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidFinishPlaying) name:TDAudioInputStreamerDidFinishPlayingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidStartPlaying) name:TDAudioInputStreamerDidStartPlayingNotification object:nil];

    return self;
}

#pragma mark - Public Methods

- (void)loadTrack:(id <TDTrack>)track
{
    self.currentTrack = track;

    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidChangeTracksNotification object:nil];

    self.elapsedTime = 0;
    [self setNowPlayingTrackWithPlaybackRate:@0];
}

- (void)loadPlaylist:(NSArray *)playlist
{
    [self loadTrackIndex:0 fromPlaylist:playlist];
}

- (void)loadTrackIndex:(NSUInteger)index fromPlaylist:(NSArray *)playlist
{
    if (index >= playlist.count) return;
    self.playlist = playlist;
    self.currentTrackIndex = index;
    [self loadTrack:self.playlist[index]];
}

- (void)play
{
    if (!self.currentTrack || self.playing) return;

    if (!self.streamer) {
        self.streamer = [[TDAudioInputStreamer alloc] initWithURL:self.currentTrack.source];
        [self.streamer start];
    } else {
        [self.streamer resume];
        [self setNowPlayingTrackWithPlaybackRate:@1];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(elapseTime) userInfo:nil repeats:YES];
    }

    self.playing = YES;
    self.paused = NO;
}

- (void)pause
{
    if (!self.currentTrack || self.paused) return;

    [self setNowPlayingTrackWithPlaybackRate:@0.000001f];
    [self.timer invalidate];
    self.timer = nil;

    [self.streamer pause];
    self.playing = NO;
    self.paused = YES;
}

- (void)stop
{
    if (!self.currentTrack || !self.streamer) return;

    self.elapsedTime = 0;
    [self.timer invalidate];
    self.timer = nil;

    [self.streamer stop];
    self.streamer = nil;
    self.playing = NO;
    self.paused = NO;
}

- (void)playNextTrack
{
    if (self.currentTrackIndex >= self.playlist.count - 1) return;
    id <TDTrack> track = self.playlist[++self.currentTrackIndex];

    [self stop];

    [self loadTrack:track];
    [self play];
}

- (void)playPreviousTrack
{
    if (self.currentTrackIndex == 0) return;
    id <TDTrack> track = self.playlist[--self.currentTrackIndex];

    [self stop];

    [self loadTrack:track];
    [self play];

}

#pragma mark - Private helpers

- (void)elapseTime
{
    self.elapsedTime++;
}

- (void)setNowPlayingTrackWithPlaybackRate:(NSNumber *)rate
{
    NSMutableDictionary *nowPlaying = [NSMutableDictionary dictionary];

    if (self.currentTrack.title) [nowPlaying setObject:self.currentTrack.title forKey:MPMediaItemPropertyTitle];
    if (self.currentTrack.artist) [nowPlaying setObject:self.currentTrack.artist forKey:MPMediaItemPropertyArtist];

    if (self.currentTrack.albumArtLarge) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.currentTrack.albumArtLarge]]]];
        if (artwork) [nowPlaying setObject:artwork forKey:MPMediaItemPropertyArtwork];
    }

    if (self.currentTrack.duration) {
        [nowPlaying setObject:self.currentTrack.duration forKey:MPMediaItemPropertyPlaybackDuration];
        [nowPlaying setObject:@(self.elapsedTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [nowPlaying setObject:rate forKey:MPNowPlayingInfoPropertyPlaybackRate];
    }

    if (self.playlist && self.playlist.count) {
        [nowPlaying setObject:@(self.playlist.count) forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
        [nowPlaying setObject:@(self.currentTrackIndex) forKey:MPNowPlayingInfoPropertyPlaybackQueueIndex];
    }

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlaying;
}

#pragma mark - Notification Handlers

- (void)audioSessionDidInterrupt:(NSNotification *)notification
{
    NSUInteger type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
        [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidForcePauseNotification object:nil];
    }
}

- (void)audioSessionDidChangeRoute:(NSNotification *)notification
{
    NSUInteger reason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];

    if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [self pause];
        [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidForcePauseNotification object:nil];
    }
}

- (void)trackDidFinishPlaying
{
    [self playNextTrack];
}

- (void)trackDidStartPlaying
{
    [self setNowPlayingTrackWithPlaybackRate:@1];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(elapseTime) userInfo:nil repeats:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
