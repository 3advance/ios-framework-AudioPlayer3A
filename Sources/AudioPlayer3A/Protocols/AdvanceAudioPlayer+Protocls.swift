import UIKit
import AVFoundation

public protocol AudioPlayerDelegate: class {
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didChangePlayerItem playerItem: AVPlayerItem, at index: Int)
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didUpdateDuration currentTime: Int, totalDuration: Int)
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didBecomeInvalid playbackState: AdvancePlaybackState)
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didPause playbackState: AdvancePlaybackState)
    func audioPlayer(_ audioPlayer: AudioPlayer3A, didPlay playbackState: AdvancePlaybackState)
}

public protocol AudioPlayerDataSource: class {
    func audioPlayer(_ audioPlayer: AudioPlayer3A, idForCurrentPlayerItem playerItem: AVPlayerItem) -> String?
    func audioPlayer(_ audioPlayer: AudioPlayer3A, shouldDisplayRemoteImageAtIndex index: Int) -> UIImage?
    func audioPlayer(_ audioPlayer: AudioPlayer3A, shouldDisplayTitleAtIndex index: Int) -> String?
}
