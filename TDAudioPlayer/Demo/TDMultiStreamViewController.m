//
//  TDMultiStreamViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/17/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDMultiStreamViewController.h"
#import "TDPlaylist.h"
#import "TDTrack.h"

@interface TDMultiStreamViewController ()

@property (strong, nonatomic) NSArray *tracks;

@end

@implementation TDMultiStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *tracksJSON = @[@{@"title":@"Get Got",@"artist":@"Death Grips",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/92942509.png",@"source":@"http://freedownloads.last.fm/download/569264057/Get%2BGot.mp3"},@{@"title":@"The Only Place",@"artist":@"Best Coast",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/75753954.png",@"source":@"http://freedownloads.last.fm/download/571137703/The%2BOnly%2BPlace.mp3"},@{@"title":@"I've Seen Footage",@"artist":@"Death Grips",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/92942509.png",@"source":@"http://freedownloads.last.fm/download/569331028/I%2527ve%2BSeen%2BFootage.mp3"},@{@"title":@"The Fever (Aye Aye)",@"artist":@"Death Grips",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/92942509.png",@"source":@"http://freedownloads.last.fm/download/569330037/The%2BFever%2B%2528Aye%2BAye%2529.mp3"},@{@"title":@"Thirteen Thirtyfive",@"artist":@"Dillon",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/76868424.png",@"source":@"http://freedownloads.last.fm/download/384950466/Thirteen%2BThirtyfive.mp3"},@{@"title":@"Lost Boys",@"artist":@"Death Grips",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/92942509.png",@"source":@"http://freedownloads.last.fm/download/569330114/Lost%2BBoys.mp3"},@{@"title":@"Blackjack",@"artist":@"Death Grips",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/92942509.png",@"source":@"http://freedownloads.last.fm/download/565138991/Blackjack.mp3"},@{@"title":@"Warrior Concerto",@"artist":@"The Glitch Mob",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/44399393.jpg",@"source":@"http://freedownloads.last.fm/download/513685968/Warrior%2BConcerto.mp3"},@{@"title":@"2080",@"artist":@"Yeasayer",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/41510221.png",@"source":@"http://freedownloads.last.fm/download/94662916/2080.mp3"},@{@"title":@"Stay Useless",@"artist":@"Cloud Nothings",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/80989201.jpg",@"source":@"http://freedownloads.last.fm/download/523916307/Stay%2BUseless.mp3"}];

    NSMutableArray *tracks = [NSMutableArray array];
    for (NSDictionary *trackJSON in tracksJSON) {
        TDTrack *track = [[TDTrack alloc] init];
        track.title = trackJSON[@"title"];
        track.artist = trackJSON[@"artist"];
        track.albumArtLarge = trackJSON[@"albumArtLarge"];
        track.source = [NSURL URLWithString:trackJSON[@"source"]];

        [tracks addObject:track];
    }

    _tracks = [tracks copy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TrackCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    TDTrack *track = [self.tracks objectAtIndex:indexPath.row];

    cell.textLabel.text = track.title;
    cell.detailTextLabel.text = track.artist;
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:track.albumArtLarge]]];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([TDAudioPlayer sharedAudioPlayer].isPlaying) {
        [[TDAudioPlayer sharedAudioPlayer] stop];
    }

    TDPlaylist *playlist = [[TDPlaylist alloc] init];
    [playlist addTracksFromArray:self.tracks];
    playlist.currentTrackIndex = indexPath.row;
    [[TDAudioPlayer sharedAudioPlayer] loadPlaylist:playlist];

    [[TDAudioPlayer sharedAudioPlayer] play];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
