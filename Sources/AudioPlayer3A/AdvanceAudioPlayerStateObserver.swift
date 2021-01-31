import AVFoundation
import Foundation

final class AudioPlayer3AStateObserver: NSObject {
    // MARK: Properties
    private var timeObserverToken: Any?
    
    // MARK: Handlers
    var timeUpdateHandler: ((Int) -> Void)?
    var playerItemUpdateHandler: (() -> Void)?
    
    // MARK: Methods
    func observeTimeChanges(in player: AVQueuePlayer) {
        removeTimeObserver(in: player)
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
            guard time.seconds.isFinite else { return }
            self.timeUpdateHandler?(Int(time.seconds))
        }
    }
    
    func removeTimeObserver(in player: AVQueuePlayer) {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    func observeCurrentItemChanges(in player: AVQueuePlayer) {
        player.addObserver(self, forKeyPath: "currentItem", options: .initial, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if (keyPath == "currentItem") {
            playerItemUpdateHandler?()
        }
    }
}
