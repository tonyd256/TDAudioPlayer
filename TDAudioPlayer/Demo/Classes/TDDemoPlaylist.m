//
//  TDDemoPlaylist.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/7/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDDemoPlaylist.h"
#import "TDDemoTrack.h"
#import "TDAudioPlayer.h"

@interface TDDemoPlaylist ()

@property (strong, nonatomic) NSMutableArray *playlist;
@property (assign, nonatomic) NSUInteger currentTrackIndex;

@end

@implementation TDDemoPlaylist

+ (instancetype)sharedPlaylist
{
    static TDDemoPlaylist *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[TDDemoPlaylist alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.playlist = [NSMutableArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextTrack:) name:TDAudioPlayerNextTrackRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousTrack:) name:TDAudioPlayerPreviousTrackRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidFinish:) name:TDAudioStreamDidFinishPlayingNotification object:nil];

    return self;
}

- (void)addTrack:(TDDemoTrack *)track
{
    [self.playlist addObject:track];
}

- (void)addTracksFromArray:(NSArray *)tracks
{
    [self.playlist addObjectsFromArray:tracks];
}

- (TDDemoTrack *)trackAtIndex:(NSUInteger)index
{
    if (index >= self.playlist.count) return nil;
    return self.playlist[index];
}

- (void)playTrackAtIndex:(NSUInteger)index
{
    if (index >= self.playlist.count) return;

    TDDemoTrack *track = self.playlist[index];
    [[TDAudioPlayer sharedAudioPlayer] loadAudioFromURL:track.source withMetaData:track.meta];
    [[TDAudioPlayer sharedAudioPlayer] play];
    self.currentTrackIndex = index;
}

- (void)playNextTrack:(NSNotification *)notification
{
    if (self.currentTrackIndex + 1 >= self.playlist.count) return;

    [self playTrackAtIndex:(self.currentTrackIndex + 1)];
}

- (void)playPreviousTrack:(NSNotification *)notification
{
    if (self.currentTrackIndex == 0) return;

    [self playTrackAtIndex:(self.currentTrackIndex - 1)];
}

- (void)audioPlayerDidFinish:(NSNotification *)notification
{
    [self playNextTrack:nil];
}

- (void)removeAllTracks
{
    [self.playlist removeAllObjects];
}

@end
