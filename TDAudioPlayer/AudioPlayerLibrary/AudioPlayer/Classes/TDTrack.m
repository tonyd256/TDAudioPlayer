//
//  TDTrack.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDTrack.h"

@implementation TDTrack

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (!self) return nil;

    self.title = [aDecoder decodeObjectForKey:@"title"];
    self.artist = [aDecoder decodeObjectForKey:@"artist"];
    self.source = [aDecoder decodeObjectForKey:@"source"];
    self.albumArtLarge = [aDecoder decodeObjectForKey:@"albumArtLarge"];
    self.albumArtSmall = [aDecoder decodeObjectForKey:@"albumArtSmall"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artist forKey:@"artist"];
    [aCoder encodeObject:self.source forKey:@"source"];
    [aCoder encodeObject:self.albumArtLarge forKey:@"albumArtLarge"];
    [aCoder encodeObject:self.albumArtSmall forKey:@"albumArtSmall"];
}

@end
