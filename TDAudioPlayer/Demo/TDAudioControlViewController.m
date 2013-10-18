//
//  TDAudioControlViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/18/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import "TDAudioControlViewController.h"
#import "TDTrack.h"

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidChangeTrack:) name:TDAudioPlayerDidChangeTracksNotification object:nil];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

//- (void)viewWillDisappear:(BOOL)animated
//{
//    [super viewWillDisappear:animated];
//    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//    [self resignFirstResponder];
//}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type != UIEventTypeRemoteControl) return;

    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPause:
            [[TDAudioPlayer sharedAudioPlayer] pause];
            [self.togglePlayPauseButton setTitle:@"Play" forState:UIControlStateNormal];
            break;

        case UIEventSubtypeRemoteControlPlay:
            [[TDAudioPlayer sharedAudioPlayer] play];
            [self.togglePlayPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
            break;

        case UIEventSubtypeRemoteControlStop:
            [[TDAudioPlayer sharedAudioPlayer] stop];
            [self.togglePlayPauseButton setTitle:@"Play" forState:UIControlStateNormal];
            break;

        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self togglePlayPause:nil];
            break;

        case UIEventSubtypeRemoteControlNextTrack:
            [[TDAudioPlayer sharedAudioPlayer] playNextTrack];
            break;

        default:
            break;
    }
}

- (void)audioPlayerDidChangeTrack:(NSNotification *)notification
{
    TDTrack *track = [TDAudioPlayer sharedAudioPlayer].currentTrack;

    self.titleLabel.text = track.title;
    self.artistLabel.text = track.artist;
    self.albumArtImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:track.albumArtLarge]]];
    [self.togglePlayPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (IBAction)togglePlayPause:(id)sender
{
    if ([TDAudioPlayer sharedAudioPlayer].isPlaying) {
        [[TDAudioPlayer sharedAudioPlayer] pause];
        [self.togglePlayPauseButton setTitle:@"Play" forState:UIControlStateNormal];

    } else {
        [[TDAudioPlayer sharedAudioPlayer] play];
        [self.togglePlayPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

@end
