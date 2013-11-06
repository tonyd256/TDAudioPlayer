//
//  TDInputStream.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/6/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import "TDStream.h"

@interface TDInputStream : NSObject <TDStream>

+ (instancetype)streamWithInputStream:(NSInputStream *)inputStream;
- (instancetype)initWithInputStream:(NSInputStream *)inputStream;

@end
