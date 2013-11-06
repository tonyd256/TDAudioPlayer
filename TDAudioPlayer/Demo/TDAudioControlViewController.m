//
//  TDAudioControlViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/18/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioControlViewController.h"
#import "TDDemoTrack.h"

@interface TDAudioControlViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumArtImage;
@property (weak, nonatomic) IBOutlet UIButton *togglePlayPauseButton;

- (IBAction)togglePlayPause:(id)sender;

@end

@implementation TDAudioControlViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidChangeTrack:) name:TDAudioPlayerDidChangeAudioNotification object:nil];
}

- (void)audioPlayerDidChangeTrack:(NSNotification *)notification
{
    if (notification.userInfo[@"meta"]) {
        TDAudioMetaInfo *meta = notification.userInfo[@"meta"];

        self.titleLabel.text = meta.title;
        self.artistLabel.text = meta.artist;
        self.albumArtImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:meta.albumArtLarge]]];
    }

    [self.togglePlayPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (IBAction)togglePlayPause:(id)sender
{
    if ([TDAudioPlayer sharedAudioPlayer].state == TDAudioPlayerStatePlaying) {
        [[TDAudioPlayer sharedAudioPlayer] pause];
        [self.togglePlayPauseButton setTitle:@"Play" forState:UIControlStateNormal];

    } else {
        [[TDAudioPlayer sharedAudioPlayer] play];
        [self.togglePlayPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

@end
