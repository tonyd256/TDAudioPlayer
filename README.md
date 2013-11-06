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

How To Use
----------

### Quick Play

To play audio from a HTTP or NSInputStream source, use the `TDAudioPlayer` singleton class to load the source into the player and then play the audio.

```Objective-C
NSURL *url = [NSURL urlFromString:@"http://web.url/to/my/audio/file"];
[[TDAudioPlayer sharedAudioPlayer] loadAudioFromURL:url];
[[TDAudioPlayer sharedAudioPlayer] play];
```

or

```Objective-C
NSInputStream *stream = [self myMethodThatGetsAnInputStream];
[[TDAudioPlayer sharedAudioPlayer] loadAudioFromStream:stream];
[[TDAudioPlayer sharedAudioPlayer] play];
```

When using the audio player singleton `[TDAudioPlayer sharedAudioPlayer]` the Audio Session will be properly configured to keep your audio playing when the app is backgrounded or the device is locked. It can also send the currently playing song info to the Now Playing Media Info on your device which will allow you to see what's playing on your lock screen.

### Set Now Playing Media Info

To view the info of the currently playing audio, create an instance of the `TDAudioMetaInfo` class and set as many of the properties as you can:

* `title` The title of the track, song, or audio piece
* `artist` The name of the composing artist
* `albumArtSmall` A URL string to the low res album art image
* `albumArtLarge` A URL string to the high res album art image
* `duration` The number of seconds of audio in the stream

Then pass this meta info along with the source to the `[TDAudioPlayer sharedAudioPlayer]` load method.

```Objective-C
TDAudioMetaInfo *meta = [[TDAudioMetaInfo alloc] init];
meta.title = @"Title of the Track";
meta.artist = @"Artist Name";
meta.albumArtSmall = @"http://www.some-address.com/track_id/low_res_image.png";
meta.albumArtLarge = @"http://www.some-address.com/track_id/high_res_image.png";
meta.duration = @356;
```

then

```Objective-C
NSURL *url = [NSURL urlFromString:@"http://web.url/to/my/audio/file"];
[[TDAudioPlayer sharedAudioPlayer] loadAudioFromURL:url withMetaData:meta];
[[TDAudioPlayer sharedAudioPlayer] play];
```

or

```Objective-C
NSInputStream *stream = [self myMethodThatGetsAnInputStream];
[[TDAudioPlayer sharedAudioPlayer] loadAudioFromStream:stream withMetaData:meta];
[[TDAudioPlayer sharedAudioPlayer] play];
```

Use the following methods to control the audio player.

```Objective-C
[[TDAudioPlayer sharedAudioPlayer] play];
[[TDAudioPlayer sharedAudioPlayer] pause];
[[TDAudioPlayer sharedAudioPlayer] stop];
```

### Lower level

You can use the lower level class, `TDAudioInputStreamer`, to play audio without using the Audio Session or Now Playing Media Info features.

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

### Notifications
When using the `TDAudioPlayer` singleton class, it will post notifications at certain points of audio playback.

* `TDAudioPlayerDidChangeAudioNotification` Posts when a new audio stream is loaded into the player.
* `TDAudioPlayerDidForcePauseNotification` Posts when the audio is forced to pause from an interruption event or headphones unplugged.
* `TDAudioPlayerDidForcePlayNotification` Posts when the audio is forced to play again from the end of an interruption event.
* `TDAudioStreamDidStartPlayingNotification` Posts when the audio starts playing.
* `TDAudioStreamDidFinishPlayingNotification` Posts when the audio has finished playing.

If you are using the lower level class `TDAudioInputStreamer`, only the last 2 notifications will ever be posted. (`TDAudioStreamDidStartPlayingNotification` and `TDAudioStreamDidFinishPlayingNotification`)

Credits
-------

This library was written by Anthony(Tony) DiPasquale while referencing Apple's provided sample code and Matt Gallagher's [AudioStreamer](https://github.com/mattgallagher/AudioStreamer) project.

License
-------

TDAudioPlayer is Copyright (c) 2013 Anthony DiPasquale. It is free software, and may be redistributed under the terms specified in the [LICENSE](https://github.com/tonyd256/TDAudioPlayer/blob/master/LICENSE) file.
