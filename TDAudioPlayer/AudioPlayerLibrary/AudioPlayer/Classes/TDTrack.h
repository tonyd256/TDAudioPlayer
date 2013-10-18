//
//  TDTrack.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDTrack : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSURL *source;
@property (strong, nonatomic) NSString *albumArtSmall;
@property (strong, nonatomic) NSString *albumArtLarge;

@end
