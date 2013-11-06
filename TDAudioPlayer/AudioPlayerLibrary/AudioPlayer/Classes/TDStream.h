//
//  TDStream.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/6/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@protocol TDStream <NSObject>

@required
- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;

@end
