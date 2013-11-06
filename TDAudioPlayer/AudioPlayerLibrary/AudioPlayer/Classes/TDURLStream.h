//
//  TDURLStream.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/6/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import "TDStream.h"

@interface TDURLStream : NSObject <TDStream>

+ (instancetype)streamWithURL:(NSURL *)url;
+ (instancetype)streamWithPath:(NSString *)path;
- (instancetype)initWithURL:(NSURL *)url;

@end
