//
//  TDDemoTrack.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/1/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDTrack.h"

@interface TDDemoTrack : NSObject <TDTrack>

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSURL *source;
@property (strong, nonatomic) NSString *albumArtSmall;
@property (strong, nonatomic) NSString *albumArtLarge;
@property (assign, nonatomic) NSUInteger duration;

@end
