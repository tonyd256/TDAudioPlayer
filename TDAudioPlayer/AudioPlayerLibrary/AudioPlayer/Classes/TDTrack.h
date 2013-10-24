//
//  TDTrack.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@interface TDTrack : NSObject <NSCoding>

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSURL *source;
@property (strong, nonatomic) NSString *albumArtSmall;
@property (strong, nonatomic) NSString *albumArtLarge;
@property (assign, nonatomic) NSUInteger duration;

@end
