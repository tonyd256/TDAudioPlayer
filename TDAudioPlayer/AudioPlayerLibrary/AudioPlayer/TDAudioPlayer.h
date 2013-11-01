//
//  TDAudioPlayer.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import "TDTrack.h"

extern NSString *const TDAudioPlayerDidChangeTracksNotification;
extern NSString *const TDAudioPlayerDidForcePauseNotification;

@interface TDAudioPlayer : NSObject

@property (strong, nonatomic, readonly, getter = loadedPlaylist) NSArray *playlist;
@property (strong, nonatomic, readonly) id <TDTrack> currentTrack;
@property (assign, nonatomic, readonly, getter = isPlaying) BOOL playing;
@property (assign, nonatomic, readonly, getter = isPaused) BOOL paused;

+ (instancetype)sharedAudioPlayer;

- (void)loadTrack:(id <TDTrack>)track;
- (void)loadPlaylist:(NSArray *)playlist;
- (void)loadTrackIndex:(NSUInteger)index fromPlaylist:(NSArray *)playlist;

- (void)play;
- (void)pause;
- (void)stop;

- (void)playNextTrack;
- (void)playPreviousTrack;

@end
