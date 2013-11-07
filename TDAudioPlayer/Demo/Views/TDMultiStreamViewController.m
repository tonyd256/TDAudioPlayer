//
//  TDMultiStreamViewController.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/17/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDMultiStreamViewController.h"
#import "TDDemoTrack.h"
#import "TDDemoPlaylist.h"

@interface TDMultiStreamViewController ()

@property (strong, nonatomic) NSArray *tracks;

@end

@implementation TDMultiStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *tracksJSON = @[@{@"title":@"Home (RAC Mix)",@"artist":@"Edward Sharpe & The Magnetic Zeros",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/57847447.jpg",@"source":@"http://freedownloads.last.fm/download/393905560/Home%2B%2528RAC%2BMix%2529.mp3",@"duration":@360},
  @{@"title":@"The Only Place",@"artist":@"Best Coast",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/75753954.png",@"source":@"http://freedownloads.last.fm/download/571137703/The%2BOnly%2BPlace.mp3",@"duration":@162},
  @{@"title":@"Barely Legal (Continuous Mix)",@"artist":@"The White Panda",@"albumArtLarge":@"https://liketodownload.com/files/downloads/2/64921/bl%20continuous.jpg",@"source":@"http://www.mediafire.com/download/rthrtsqi36r6hpd/Bearly_Legal_(Continuous_Mix).mp3",@"duration":@3266},
  @{@"title":@"Turn It Down Animals",@"artist":@"Kaskade vs. Martin Garrix",@"albumArtLarge":@"https://i3.sndcdn.com/artworks-000061299883-f2v2bt-t120x120.jpg?3eddc42",@"source":@"https://api.soundcloud.com/tracks/117498039/download?client_id=b45b1aa10f1ac2941910a7f0d10f8e28",@"duration":@361},
  @{@"title":@"Thirteen Thirtyfive",@"artist":@"Dillon",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/76868424.png",@"source":@"http://freedownloads.last.fm/download/384950466/Thirteen%2BThirtyfive.mp3",@"duration":@223},
  @{@"title":@"Spectrum (Say My Name)",@"artist":@"Florence & The Machine",@"albumArtLarge":@"https://i4.sndcdn.com/artworks-000048547825-k4ke8w-t120x120.jpg?3eddc42",@"source":@"http://dl.soundowl.com/5e24.mp3",@"duration":@360},
  @{@"title":@"Radioactive (dBerrie remix)",@"artist":@"Imagine Dragons",@"albumArtLarge":@"https://i4.sndcdn.com/artworks-000047724697-kcvj5w-t120x120.jpg?3eddc42",@"source":@"https://api.soundcloud.com/tracks/91647531/download?client_id=b45b1aa10f1ac2941910a7f0d10f8e28",@"duration":@421},
  @{@"title":@"Warrior Concerto",@"artist":@"The Glitch Mob",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/44399393.jpg",@"source":@"http://freedownloads.last.fm/download/513685968/Warrior%2BConcerto.mp3",@"duration":@219},
  @{@"title":@"2080",@"artist":@"Yeasayer",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/41510221.png",@"source":@"http://freedownloads.last.fm/download/94662916/2080.mp3",@"duration":@323},
  @{@"title":@"Stay Useless",@"artist":@"Cloud Nothings",@"albumArtLarge":@"http://userserve-ak.last.fm/serve/64s/80989201.jpg",@"source":@"http://freedownloads.last.fm/download/523916307/Stay%2BUseless.mp3",@"duration":@166}];

    NSMutableArray *tracks = [NSMutableArray array];
    for (NSDictionary *trackJSON in tracksJSON) {
        TDDemoTrack *track = [[TDDemoTrack alloc] init];
        track.meta.title = trackJSON[@"title"];
        track.meta.artist = trackJSON[@"artist"];
        track.meta.albumArtLarge = trackJSON[@"albumArtLarge"];
        track.source = [NSURL URLWithString:trackJSON[@"source"]];
        track.meta.duration = trackJSON[@"duration"];

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
    TDDemoTrack *track = [self.tracks objectAtIndex:indexPath.row];

    cell.textLabel.text = track.meta.title;
    cell.detailTextLabel.text = track.meta.artist;
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:track.meta.albumArtLarge]]];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([TDAudioPlayer sharedAudioPlayer].state == TDAudioPlayerStatePlaying) {
        [[TDAudioPlayer sharedAudioPlayer] stop];
    }

    [[TDDemoPlaylist sharedPlaylist] removeAllTracks];
    [[TDDemoPlaylist sharedPlaylist] addTracksFromArray:self.tracks];
    [[TDDemoPlaylist sharedPlaylist] playTrackAtIndex:indexPath.row];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
