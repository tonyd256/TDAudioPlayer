//
//  TDSingleStreamViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDSingleStreamViewController.h"
#import "TDAudioPlayer.h"

@interface TDSingleStreamViewController ()

@property (strong, nonatomic) TDAudioInputStreamer *streamer;

@end

@implementation TDSingleStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)playSineWave:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.stecrecords.com/media/mp3/testTones/StecMetronomeTestTone440Hz5Minutes.mp3"];

    self.streamer = [[TDAudioInputStreamer alloc] initWithURL:url];
    [self.streamer start];
}

- (IBAction)playMP3:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://freedownloads.last.fm/download/513685968/Warrior%2BConcerto.mp3"];

    [[TDAudioPlayer sharedAudioPlayer] loadAudioFromStream:[TDURLStream streamWithURL:url]];
    [[TDAudioPlayer sharedAudioPlayer] play];
}
@end
