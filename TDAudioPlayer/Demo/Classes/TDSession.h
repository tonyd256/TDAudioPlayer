//
//  TDSession.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/15/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@class TDSession, MCPeerID, MCBrowserViewController;
@protocol TDSessionDelegate <NSObject>

- (void)session:(TDSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID;
- (void)session:(TDSession *)session didReceiveAudioData:(uint8_t)data fromPeer:(MCPeerID *)peerID;

@end

@interface TDSession : NSObject

- (instancetype)initWithPeerDisplayName:(NSString *)name;

- (void)startAdvertisingForServiceType:(NSString *)type discoveryInfo:(NSDictionary *)info;
- (MCBrowserViewController *)browserViewControllerForSeriviceType:(NSString *)type;

- (NSArray *)connectedPeers;
- (NSArray *)openOutputStreams;
- (NSOutputStream *)outputStreamForPeer:(MCPeerID *)peer;

@end
