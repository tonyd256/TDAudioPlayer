//
//  TDPlaylist.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@class TDTrack;

@interface TDPlaylist : NSObject <NSCoding>

@property (strong, nonatomic, readonly) NSArray *trackList;
@property (assign, nonatomic) NSUInteger currentTrackIndex;

- (void)addTrack:(TDTrack *)track;
- (void)addTracksFromArray:(NSArray *)tracks;

- (TDTrack *)currentTrack;
- (TDTrack *)nextTrack;
- (TDTrack *)previousTrack;

@end
