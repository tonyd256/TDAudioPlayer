//
//  TDMultipeerGuestViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/15/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDMultipeerGuestViewController.h"
#import "TDSession.h"

@interface TDMultipeerGuestViewController ()

@property (strong, nonatomic) TDSession *session;

@end

@implementation TDMultipeerGuestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.session = [[TDSession alloc] initWithPeerDisplayName:@"Guest"];
    [self.session startAdvertisingForServiceType:@"dance-party" discoveryInfo:nil];
}

@end
