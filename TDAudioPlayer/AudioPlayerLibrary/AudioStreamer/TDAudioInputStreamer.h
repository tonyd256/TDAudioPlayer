//
//  TDAudioInputStreamer.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

extern NSString *const TDAudioInputStreamerDidFinishNotification;
extern NSString *const TDAudioInputStreamerDidStartPlayingNotification;

@interface TDAudioInputStreamer : NSObject

@property (assign, nonatomic) NSUInteger audioStreamReadMaxLength;
@property (assign, nonatomic) NSUInteger audioQueueBufferSize;
@property (assign, nonatomic) NSUInteger audioQueueBufferCount;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithInputStream:(NSInputStream *)inputStream;

- (void)start;

- (void)resume;
- (void)pause;
- (void)stop;

@end
