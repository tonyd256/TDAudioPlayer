//
//  TDAudioPlayer.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

#import "TDAudioMetaInfo.h"
#import "TDAudioInputStreamer.h"
#import "TDAudioPlayerConstants.h"
#import "TDStream.h"
#import "TDURLStream.h"
#import "TDInputStream.h"

typedef NS_ENUM(NSInteger, TDAudioPlayerState) {
    TDAudioPlayerStateStopped,
    TDAudioPlayerStateStarting,
    TDAudioPlayerStatePlaying,
    TDAudioPlayerStatePaused
};

@interface TDAudioPlayer : NSObject

@property (assign, nonatomic, readonly) TDAudioPlayerState state;

+ (instancetype)sharedAudioPlayer;

- (void)loadAudioFromStream:(id<TDStream>)stream;
- (void)loadAudioFromStream:(id<TDStream>)stream withMetaData:(TDAudioMetaInfo *)meta;

- (void)play;
- (void)pause;
- (void)stop;

@end
