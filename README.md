# TDAudioPlayer

TDAudioPlayer is a library for playing streams from HTTP or NSInputStream sources.  It's initial motivation came from the need to stream audio over NSInputStreams in a MultiPeer Connectivity application and evolved to support HTTP streams as well.

Installation
------------

To install with CocoaPods, add this to your `Podfile`

```ruby
pod 'TDAudioPlayer'
```
and then run this in your shell:

```shell
pod install
```

Supported Versions
------------------

TDAudioPlayer is written and tested in XCode 5 using iOS 7; however, I believe it would work in iOS 6 just fine.  I will change the podspec once it has been tested in iOS 6.

How To Use With HTTP Streams
----------------------------

### Single Audio Stream
To play a single stream, create an instance of `TDAudioInputStreamer` and instantiate it with the URL to the audio stream.

```Objective-C
NSURL *url = [NSURL urlFromString:@"http://web.url/to/my/audio/file"];
TDAudioInputStreamer *streamer = [[TDAudioInputStreamer alloc] initWithURL:url];
```

To start playing audio, call `start`.  Then use the following methods to control the audio flow.

```Objective-C
[streamer start];
[streamer pause];
[streamer resume];
[streamer stop];
```

### Multiple Audio Streams and Full Featured Use
To play multiple songs or to make use of all the other features TDAudioPlayer offers, use the `TDAudioPlayer` singleton instead. Any audio streams played with `TDAudioPlayer` must conform to the `TDTrack` protocol. Create your own custom subclass of `NSObject` and conform to the protocol. [TDDemoTrack](https://github.com/tonyd256/TDAudioPlayer/blob/master/TDAudioPlayer/Demo/TDDemoTrack.h) is an example of implementing the required properties needed to conform to the protocol. Try to set as many of these properties as possible.

#### TDTrack Protocol Properties
The following properties from the `TDTrack` protocol are provided for convenience and to supply info to the Now Playing feature of the iDevice lock screen.

* `title` The title of the track, song, or audio piece
* `artist` The name of the composing artist
* `source` The source URL to the audio file
* `albumArtSmall` A URL string to the low res album art image
* `albumArtLarge` A URL string to the high res album art image
* `duration` The number of seconds of audio in the stream

#### Playing
After you have your custom `TDTrack` objects, pass one into the singleton player and play it.

```Objective-C
[[TDAudioPlayer sharedAudioPlayer] loadTrack:myTrack];
[[TDAudioPlayer sharedAudioPlayer] play];
```

To play a list of tracks, pass in an array of tracks and the audio player will play them in order starting with the first track.

```Objective-C
[[TDAudioPlayer sharedAudioPlayer] loadPlaylist:myArrayOfTracks];
[[TDAudioPlayer sharedAudioPlayer] play];
```

If you'd rather start playing a track somewhere in the middle of the list, use this instead.

```Objective-C
[[TDAudioPlayer sharedAudioPlayer] loadTrackIndex:indexOfTrackToStartOn fromPlaylist:myArrayOfTracks];
[[TDAudioPlayer sharedAudioPlayer] play];
```

To control the flow of audio, use the following methods

```Objective-C
[[TDAudioPlayer sharedAudioPlayer] play];
[[TDAudioPlayer sharedAudioPlayer] pause];
[[TDAudioPlayer sharedAudioPlayer] stop];
[[TDAudioPlayer sharedAudioPlayer] playNextTrack];
[[TDAudioPlayer sharedAudioPlayer] playPreviousTrack];
```

#### Features
When using the audio player singleton `[TDAudioPlayer sharedAudioPlayer]` the Audio Session will be properly configured to keep your audio playing when the app is backgrounded or the device is locked.  It will send the currently playing song info (provided you set all the `TDTrack` properties) to the Now Playing Media Info on your device which will allow you to see what's playing on your lock screen. It will implement the lock screen controls and the iRemote controls so you can play, pause, and skip songs without having to unlock the device. AirPlay functionality is to come in the near future.

Credits
-------

This library was written by Anthony(Tony) DiPasquale while referencing Apple's provided sample code and Matt Gallagher's [AudioStreamer](https://github.com/mattgallagher/AudioStreamer) project.

License
-------

TDAudioPlayer is Copyright (c) 2013 Anthony DiPasquale. It is free software, and may be redistributed under the terms specified in the [LICENSE](https://github.com/tonyd256/TDAudioPlayer/blob/master/LICENSE) file.
