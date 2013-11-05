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

@interface TDAudioPlayer ()

@property (strong, nonatomic) TDAudioInputStreamer *streamer;
@property (strong, nonatomic) NSMutableDictionary *nowPlayingMetaInfo;
@property (assign, nonatomic) TDAudioPlayerState state;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChangeRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioDidStartPlaying) name:TDAudioStreamDidStartPlayingNotification object:nil];

    return self;
}

#pragma mark - Audio Loading

- (void)loadAudioFromURL:(NSURL *)url
{
    [self loadAudioFromURL:url withMetaData:nil];
}

- (void)loadAudioFromURL:(NSURL *)url withMetaData:(TDAudioMetaInfo *)meta
{
    [self reset];
    self.streamer = [[TDAudioInputStreamer alloc] initWithURL:url];
    [self changeAudioMetaInfo:meta];
}

- (void)loadAudioFromStream:(NSInputStream *)stream
{
    [self loadAudioFromStream:stream withMetaData:nil];
}

- (void)loadAudioFromStream:(NSInputStream *)stream withMetaData:(TDAudioMetaInfo *)meta
{
    [self reset];
    self.streamer = [[TDAudioInputStreamer alloc] initWithInputStream:stream];
    [self changeAudioMetaInfo:meta];
}

- (void)reset
{
    [self.streamer stop];
    self.streamer = nil;

    self.state = TDAudioPlayerStateStopped;
    self.elapsedTime = 0;
    [self clearTimer];
}

#pragma mark - Audio Controls

- (void)play
{
    if (!self.streamer || self.state == TDAudioPlayerStatePlaying) return;
    if (self.state == TDAudioPlayerStateStopped) return [self start];

    [self.streamer resume];
    [self setNowPlayingInfoWithPlaybackRate:@1];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(elapseTime) userInfo:nil repeats:YES];
    self.state = TDAudioPlayerStatePlaying;
}

- (void)start
{
    if (self.state == TDAudioPlayerStateStarting) return;
    [self.streamer start];
    self.state = TDAudioPlayerStateStarting;
}

- (void)pause
{
    if (!self.streamer || self.state == TDAudioPlayerStatePaused) return;

    [self setNowPlayingInfoWithPlaybackRate:@0.000001f];
    [self clearTimer];

    [self.streamer pause];
    self.state = TDAudioPlayerStatePaused;
}

- (void)stop
{
    if (!self.streamer || self.state == TDAudioPlayerStateStopped) return;
    [self reset];
}

#pragma mark - Timer Helpers

- (void)elapseTime
{
    self.elapsedTime++;
}

- (void)clearTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - Now Playing Info Helpers

- (void)changeAudioMetaInfo:(TDAudioMetaInfo *)meta
{
    [self setNowPlayingInfoWithMetaInfo:meta];

    if (!meta)
        return [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidChangeAudioNotification object:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioPlayerDidChangeAudioNotification object:nil userInfo:@{@"meta": meta}];
}

- (void)setNowPlayingInfoWithMetaInfo:(TDAudioMetaInfo *)info
{
    if (!info) return;

    if (!self.nowPlayingMetaInfo)
        self.nowPlayingMetaInfo = [NSMutableDictionary dictionary];

    if (info.title) self.nowPlayingMetaInfo[MPMediaItemPropertyTitle] = info.title;
    if (info.artist) self.nowPlayingMetaInfo[MPMediaItemPropertyArtist] = info.artist;

    if (info.albumArtLarge) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:info.albumArtLarge]]]];
        if (artwork) self.nowPlayingMetaInfo[MPMediaItemPropertyArtwork] = artwork;
    }

    if (info.duration) self.nowPlayingMetaInfo[MPMediaItemPropertyPlaybackDuration] = info.duration;

    [self setNowPlayingInfoWithPlaybackRate:@0];
}

- (void)setNowPlayingInfoWithPlaybackRate:(NSNumber *)rate
{
    if (!self.nowPlayingMetaInfo) return;

    if (!self.nowPlayingMetaInfo[MPMediaItemPropertyPlaybackDuration]) {
        self.nowPlayingMetaInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate;
        self.nowPlayingMetaInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.elapsedTime);
    }

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.nowPlayingMetaInfo;
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

- (void)audioDidStartPlaying
{
    [self setNowPlayingInfoWithPlaybackRate:@1];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(elapseTime) userInfo:nil repeats:YES];
    self.state = TDAudioPlayerStatePlaying;
}

#pragma mark - Cleanup

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
