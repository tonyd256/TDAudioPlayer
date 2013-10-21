//
//  TDAudioPlayer.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

extern NSString *const TDAudioPlayerDidChangeTracksNotification;

@class TDTrack, TDPlaylist;

@interface TDAudioPlayer : NSObject

@property (strong, nonatomic, readonly) TDPlaylist *loadedPlaylist;
@property (strong, nonatomic, readonly) TDTrack *currentTrack;
@property (assign, nonatomic, readonly, getter = isPlaying) BOOL playing;
@property (assign, nonatomic, readonly, getter = isPaused) BOOL paused;

+ (instancetype)sharedAudioPlayer;

- (void)loadPlaylist:(TDPlaylist *)playlist;

- (void)play;
- (void)pause;
- (void)stop;

- (void)playNextTrack;
- (void)playPreviousTrack;

@end
