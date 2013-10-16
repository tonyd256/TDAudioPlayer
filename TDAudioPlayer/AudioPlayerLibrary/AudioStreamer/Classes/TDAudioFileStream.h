//
//  TDAudioFileStream.h
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
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

@property (assign, atomic) AudioStreamBasicDescription basicDescription;
@property (assign, atomic) UInt64 byteCount;
@property (assign, atomic) UInt32 packetBufferSize;
@property (assign, atomic) void *magicCookieData;
@property (assign, atomic) UInt32 magicCookieLength;
@property (assign, atomic) BOOL discontinuous;
@property (weak, nonatomic) id<TDAudioFileStreamDelegate> delegate;

- (instancetype)init;

- (void)parseData:(const void *)data length:(UInt32)length;

@end
