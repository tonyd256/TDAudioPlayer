//
//  TDDemoPlaylist.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/7/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@class TDDemoTrack;

@interface TDDemoPlaylist : NSObject

+ (instancetype)sharedPlaylist;

- (void)addTrack:(TDDemoTrack *)track;
- (void)addTracksFromArray:(NSArray *)tracks;
- (TDDemoTrack *)trackAtIndex:(NSUInteger)index;

- (void)playTrackAtIndex:(NSUInteger)index;

- (void)removeAllTracks;

@end
