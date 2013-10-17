//
//  TDAudioFileStream.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import "TDAudioFileStream.h"

@interface TDAudioFileStream ()

@property (assign, nonatomic) AudioFileStreamID audioFileStreamID;

- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags;
- (void)didReceivePackets:(const void *)packets descriptions:(AudioStreamPacketDescription *)descriptions numberOfPackets:(UInt32)numberOfPackets numberOfBytes:(UInt32)numberOfBytes;

@end

void TDAudioFileStreamPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStreamID, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    TDAudioFileStream *audioFileStream = (__bridge TDAudioFileStream *)inClientData;
    [audioFileStream didChangeProperty:inPropertyID flags:ioFlags];
}

void TDAudioFileStreamPacketsListener(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    TDAudioFileStream *audioFileStream = (__bridge TDAudioFileStream *)inClientData;
    [audioFileStream didReceivePackets:inInputData descriptions:inPacketDescriptions numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes];
}

@implementation TDAudioFileStream

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    OSStatus err = AudioFileStreamOpen((__bridge void *)self, TDAudioFileStreamPropertyListener, TDAudioFileStreamPacketsListener, 0, &_audioFileStreamID);

    if (err) {
        NSLog(@"Error opening audio file stream");
        return nil;
    }

    _discontinuous = YES;

    return self;
}

- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags
{
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        // all properties are ready and data is ready

        // get the file basic description
        UInt32 basicDescriptionSize = sizeof(_basicDescription);
        OSStatus err = AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_DataFormat, &basicDescriptionSize, &_basicDescription);

        if (err) {
            // set fail status
            NSLog(@"Error getting basic description");
            return;
        }

        UInt32 byteCountSize;
        AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_AudioDataByteCount, &byteCountSize, &_byteCount);

        UInt32 size = sizeof(UInt32);
        err = AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &size, &_packetBufferSize);

        if (err || _packetBufferSize == 0) {
            AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &size, &_packetBufferSize);
        }

        // add magic cookie data id if exists
        Boolean writeable;
        err = AudioFileStreamGetPropertyInfo(self.audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &_magicCookieLength, &writeable);

        if (!err) {
            _magicCookieData = calloc(1, _magicCookieLength);
            AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &_magicCookieLength, _magicCookieData);
        }

        [self.delegate audioFileStreamDidBecomeReady:self];
    }
}

- (void)didReceivePackets:(const void *)packets descriptions:(AudioStreamPacketDescription *)descriptions numberOfPackets:(UInt32)numberOfPackets numberOfBytes:(UInt32)numberOfBytes
{
    // packet descriptions mean the data is VBR (variable bit rate)
    if (descriptions) {
        for (NSUInteger i = 0; i < numberOfPackets; i++) {
            SInt64 packetOffset = descriptions[i].mStartOffset;
            UInt32 packetSize = descriptions[i].mDataByteSize;

            [self.delegate audioFileStream:self didReceiveData:(const void *)(packets + packetOffset) length:packetSize description:(AudioStreamPacketDescription)descriptions[i]];
        }
    } else {
        // otherwise the data is CBR (constant bit rate)
        [self.delegate audioFileStream:self didReceiveData:(const void *)packets length:numberOfBytes];
    }
}

- (void)parseData:(const void *)data length:(UInt32)length
{
    OSStatus err;

    if (self.discontinuous) {
        err = AudioFileStreamParseBytes(self.audioFileStreamID, length, data, kAudioFileStreamParseFlag_Discontinuity);
        self.discontinuous = NO;
    } else {
        err = AudioFileStreamParseBytes(self.audioFileStreamID, length, data, 0);
    }

    if (err) {
        NSLog(@"Error parsing data into file stream");
    }
}

- (void)dealloc
{
    free(_magicCookieData);
}

@end
