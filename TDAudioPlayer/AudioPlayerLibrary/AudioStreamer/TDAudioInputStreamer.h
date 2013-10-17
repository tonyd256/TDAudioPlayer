//
//  TDAudioInputStreamer.h
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDAudioInputStreamer : NSObject

@property (assign, nonatomic) NSUInteger audioStreamReadMaxLength;
@property (assign, nonatomic) NSUInteger audioQueueBufferSize;
@property (assign, nonatomic) NSUInteger audioQueueBufferCount;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithInputStream:(NSInputStream *)inputStream;

- (void)start;

@end
