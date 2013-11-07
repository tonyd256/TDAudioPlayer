//
//  TDDemoTrack.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/1/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@class TDAudioMetaInfo;

@interface TDDemoTrack : NSObject

@property (strong, nonatomic) NSURL *source;
@property (strong, nonatomic) TDAudioMetaInfo *meta;

@end
