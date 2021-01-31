import UIKit
import AVFoundation

public protocol AudioPlayerDelegate: class {
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, didChangePlayerItem playerItem: AVPlayerItem, at index: Int)
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, didUpdateDuration currentTime: Int, totalDuration: Int)
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, didBecomeInvalid playbackState: AdvancePlaybackState)
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, didPause playbackState: AdvancePlaybackState)
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, didPlay playbackState: AdvancePlaybackState)
}

public protocol AudioPlayerDataSource: class {
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, idForCurrentPlayerItem playerItem: AVPlayerItem) -> String?
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, shouldDisplayRemoteImageAtIndex index: Int) -> UIImage?
    func audioPlayer(_ audioPlayer: AdvanceAudioPlayer, shouldDisplayTitleAtIndex index: Int) -> String?
}
