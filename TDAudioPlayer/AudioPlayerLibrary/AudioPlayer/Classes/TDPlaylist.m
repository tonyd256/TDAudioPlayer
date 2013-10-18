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

- (TDTrack *)nextTrack
{
    TDTrack *track = [self.playlist firstObject];
    [self.playlist removeObject:track];
    return track;
}

@end
