//
//  TDAudioPlayer.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TDAudioMetaInfo.h"
#import "TDAudioInputStreamer.h"
#import "TDAudioPlayerConstants.h"

typedef NS_ENUM(NSInteger, TDAudioPlayerState) {
    TDAudioPlayerStateStopped,
    TDAudioPlayerStateStarting,
    TDAudioPlayerStatePlaying,
    TDAudioPlayerStatePaused
};

@interface TDAudioPlayer : NSObject

@property (assign, nonatomic, readonly) TDAudioPlayerState state;

+ (instancetype)sharedAudioPlayer;

- (void)loadAudioFromURL:(NSURL *)url;
- (void)loadAudioFromURL:(NSURL *)url withMetaData:(TDAudioMetaInfo *)meta;

- (void)loadAudioFromStream:(NSInputStream *)stream;
- (void)loadAudioFromStream:(NSInputStream *)stream withMetaData:(TDAudioMetaInfo *)meta;

- (void)play;
- (void)pause;
- (void)stop;

- (void)handleRemoteControlEvent:(UIEvent *)event;

@end
