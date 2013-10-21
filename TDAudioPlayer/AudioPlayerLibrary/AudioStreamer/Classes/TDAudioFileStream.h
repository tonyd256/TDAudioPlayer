//
//  TDAudioFileStream.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class TDAudioFileStream;
@protocol TDAudioFileStreamDelegate <NSObject>

@required
- (void)audioFileStreamDidBecomeReady:(TDAudioFileStream *)audioFileStream;
- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length description:(AudioStreamPacketDescription)description;
- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length;

@end

@interface TDAudioFileStream : NSObject

@property (assign, nonatomic) AudioStreamBasicDescription basicDescription;
@property (assign, nonatomic) UInt64 byteCount;
@property (assign, nonatomic) UInt32 packetBufferSize;
@property (assign, nonatomic) void *magicCookieData;
@property (assign, nonatomic) UInt32 magicCookieLength;
@property (assign, nonatomic) BOOL discontinuous;
@property (weak, nonatomic) id<TDAudioFileStreamDelegate> delegate;

- (instancetype)init;

- (void)parseData:(const void *)data length:(UInt32)length;

@end
