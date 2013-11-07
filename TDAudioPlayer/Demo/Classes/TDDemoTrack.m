//
//  TDDemoTrack.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/1/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDDemoTrack.h"
#import "TDAudioMetaInfo.h"

@implementation TDDemoTrack

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.meta = [[TDAudioMetaInfo alloc] init];

    return self;
}

@end
