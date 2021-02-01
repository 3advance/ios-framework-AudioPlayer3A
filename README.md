# AudioPlayer3A

## Features
 
- Support for standard media player controls (play, pause, stop, seek, skip)
- Support for Apple Control Center 
- Support for playing in audio in the background

### Installation

You can install AudioPlayer3A using Swift Package Manager.
If you are using Xcode 11 or later:

1. Click File
2. Swift Packages
3. Add Package Dependency...
4. Specify the git URL for AudioPlayer3A.
```swift
https://github.com/3advance/ios-framework-AudioPlayer3A
```

```swift
import AudioPlayer3A
```

#### Manually

You can also integrate AudioPlayer3A into your project manually by simply dragging the `Sources` Folder into your Xcode project.

## Usage

### Loading

```swift
let audioPlayer = AudioPlayer3A.shared
let myAudioURLs = [URL(string: "myaudio.com/id/1"), URL(string: "myaudio.com/id/2")]
try audioPlayer.loadPlayerItems(from: myAudioURLs.compactMap{$0})
audioPlayer.play()
```

### Getting Player Updates

```swift
let audioController = AudioController()
let audioPlayer = AudioPlayer3A.shared
audioPlayer.delegate = audioController

...
extension AudioController: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didChangePlayerItem playerItem: AVPlayerItem, at index: Int) { ... }
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didUpdateDuration currentTime: Int, totalDuration: Int) { ... }
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didBecomeInvalid playbackState: AdvancePlaybackState) { ... }
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didPause playbackState: AdvancePlaybackState) { ... }
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didPlay playbackState: AdvancePlaybackState) { ... }
}
```

### Configuring the Control Center
```swift
let audioController = AudioController()
let audioPlayer = AudioPlayer3A.shared
audioPlayer.dataSource = audioController

...
extension AudioController: AudioPlayerDataSource {
    func audioPlayer(_ audioPlayer: AudioPlayer3A, shouldDisplayRemoteImageAtIndex index: Int) -> UIImage? { ... }
    func audioPlayer(_ audioPlayer: AudioPlayer3A, shouldDisplayTitleAtIndex index: Int) -> String? { ... }
}
```

## License

```
AudioPlayer3A
Copyright (c) 2021 3Advance LLC mevansjr@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
