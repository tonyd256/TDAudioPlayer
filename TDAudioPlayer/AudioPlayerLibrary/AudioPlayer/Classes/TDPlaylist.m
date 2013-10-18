//
//  TDPlaylist.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import "TDPlaylist.h"
#import "TDTrack.h"

@interface TDPlaylist ()

@property (strong, nonatomic) NSMutableArray *playlist;

@end

@implementation TDPlaylist

#pragma mark - Properties

- (NSMutableArray *)playlist
{
    if (!_playlist)
        _playlist = [NSMutableArray array];

    return _playlist;
}

- (NSArray *)trackList
{
    return [self.playlist copy];
}

#pragma mark - Public Methods

- (void)addTrack:(TDTrack *)track
{
    [self.playlist addObject:track];
}

- (void)addTracksFromArray:(NSArray *)tracks
{
    [self.playlist addObjectsFromArray:tracks];
}

- (TDTrack *)currentTrack
{
    return self.playlist[self.currentTrackIndex];
}

- (TDTrack *)nextTrack
{
    if (self.currentTrackIndex == self.playlist.count - 1) return nil;

    TDTrack *track = self.playlist[++self.currentTrackIndex];
    return track;
}

- (TDTrack *)previousTrack
{
    if (self.currentTrackIndex == 0) return nil;

    TDTrack *track = self.playlist[--self.currentTrackIndex];
    return track;
}

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (!self) return nil;

    self.playlist = [aDecoder decodeObjectForKey:@"playlist"];
    self.currentTrackIndex = [[aDecoder decodeObjectForKey:@"currentTrackIndex"] unsignedIntegerValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.playlist forKey:@"playlist"];
    [aCoder encodeObject:@(self.currentTrackIndex) forKey:@"currentTrackIndex"];
}

@end
