//
//  TDPlaylist.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDTrack;

@interface TDPlaylist : NSObject

@property (strong, nonatomic, readonly) NSArray *trackList;

- (void)addTrack:(TDTrack *)track;
- (void)addTracksFromArray:(NSArray *)tracks;
- (TDTrack *)nextTrack;

@end
