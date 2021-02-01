import AVFoundation
import Foundation
import MediaPlayer

final class AudioControlCenterController {
    // MARK: Properties
    weak var dataSource: AudioPlayerDataSource?
    
    // MARK: Handlers
    var nextHandler: (() -> Void)?
    var previousHandler: (() -> Void)?
    var playHandler: (() -> Void)?
    var pauseHandler: (() -> Void)?

    // MARK: Methods
    func play() {
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }
    
    func pause() {
        MPNowPlayingInfoCenter.default().playbackState = .paused
    }
    
    func stop() {
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
    
    func configureNowPlayingInfoCenter(config: RemotePlayConfig) {
        var nowPlayingInfo = [String : Any]()
        if let displayImage = config.image {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: CGSize(width: 50, height: 50)) { size in
                return displayImage
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = config.currentDuration
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = config.totalDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = config.rate
        nowPlayingInfo[MPMediaItemPropertyTitle] = config.title
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func clearRemoteNowPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    func setup() {
        let commandCenter = MPRemoteCommandCenter.shared();
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { event in
            self.nextHandler?()
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { event in
            self.pauseHandler?()
            return .success
        }
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { event in
            self.nextHandler?()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { event in
            self.previousHandler?()
            return .success
        }
    }
}
