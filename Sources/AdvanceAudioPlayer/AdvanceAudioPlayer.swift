import AVFoundation

public class AdvanceAudioPlayer {
    static let shared = AdvanceAudioPlayer()
    
    // MARK: - Dependencies
    weak var delegate: AudioPlayerDelegate?
    weak var dataSource: AudioPlayerDataSource?
    
    let audioSession = AVAudioSession.sharedInstance()
    let playerObserver = AdvanceAudioPlayerStateObserver()
    let commandCenterController = AudioCommandCenterController()
    
    // MARK: - Properties
    private var looper: AVPlayerLooper?
    private let player: AVQueuePlayer = AVQueuePlayer()
    private(set) var playerQueue: [AVPlayerItem] = []
    var audioCategoryOptions: AVAudioSession.CategoryOptions = [
        .mixWithOthers, .allowAirPlay, .defaultToSpeaker
    ]

    // MARK: - State
    private(set) var playbackState: AdvancePlaybackState = .pending {
        didSet {
            handlePlaybackStateChange()
        }
    }
    var isPaused: Bool {
        return player.rate == 0
    }
    private(set) var isRepeatEnabled: Bool = false {
        didSet {
            if isRepeatEnabled {
                looper = AVPlayerLooper(player: player, templateItem: currentPlayerItem!)
            } else {
                looper?.disableLooping()
            }
        }
    }
    var currentPlayerItem: AVPlayerItem? {
        return player.currentItem
    }
    var currentPlayerItemID: String? {
        if let currentPlayerItem = currentPlayerItem {
            return dataSource?.audioPlayer(self, idForCurrentPlayerItem: currentPlayerItem)
        } else {
            return nil
        }
    }
    var indexOfCurrentPlayerItem: Int? {
        guard let currentItem = currentPlayerItem else { return nil }
        return playerQueue.firstIndex(of: currentItem)
    }
    var isPlayerAtLastItem: Bool {
        return playerQueue.count-1 == indexOfCurrentPlayerItem
    }
    
    // MARK: - Setup
    func loadPlayerItems(from avAssets: [(String, AVAsset)], playAtIndex: Int) {
        do {
            try audioSession.setCategory(
                AVAudioSession.Category.playback,
                mode: AVAudioSession.Mode.default,
                options: audioCategoryOptions
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio Session is Active")
            let playerItems = avAssets.map{ AVPlayerItem(asset: $0.1) }
            playerQueue = playerItems
            configurePlayer(playerItems, playAtIndex)
            configureObserverHandlers()
            configureCommandCenterHandlers()
            playerObserver.observeTimeChanges(in: player)
            playerObserver.observeCurrentItemChanges(in: player)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Controls
    /// Handles playing and pausing for the current player Item.
    func play() {
        commandCenterController.setupRemoteCommandCenter()
        configureCommandCenter()
        if isPaused {
            player.play()
            playbackState = .playing
        } else {
            player.pause()
            playbackState = .paused
        }
        if let playerItem = currentPlayerItem, let index = indexOfCurrentPlayerItem {
            delegate?.audioPlayer(self, didChangePlayerItem: playerItem, at: index)
        }
    }
    
    func pauseIfNeeded() {
        if !isPaused { play() }
    }
    
    func stop() {
        player.pause()
        player.removeAllItems()
        playerQueue.removeAll()
        playerObserver.removeTimeObserver(in: player)
        try? audioSession.setActive(false)
        commandCenterController.clearRemoteNowPlayingInfoCenter()
    }
    
    func goBackFifteenSeconds() {
        let currentTime = player.currentTime().seconds
        guard currentTime != 0 else { return }
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: currentTime - 15, preferredTimescale: timeScale))
    }
    
    func goForwardFifteenSeconds() {
        let currentTime = player.currentTime().seconds
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: currentTime + 15, preferredTimescale: timeScale))
    }
    
    func seek(to value: Float) {
        let newTime = Double(value)
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: timeScale))
    }
    
    @discardableResult func toggleLooping() -> Bool {
        isRepeatEnabled = !isRepeatEnabled
        return isRepeatEnabled
    }
    
    func skipForward() {
        if !isPlayerAtLastItem {
            player.advanceToNextItem()
        }
    }
    
    func skipBack() {
        if let indexOfCurrentPlayerItem = indexOfCurrentPlayerItem, indexOfCurrentPlayerItem > 0 {
            configurePlayer(playerQueue, indexOfCurrentPlayerItem - 1)
        }
        currentPlayerItem?.seek(to: .zero, completionHandler: nil)
    }
}

// MARK: - Private Helpers
extension AdvanceAudioPlayer {
    private func handlePlaybackStateChange() {
        switch playbackState {
        case .playing:
            player.play()
            commandCenterController.play()
            delegate?.audioPlayer(self, didPlay: playbackState)
        case .paused:
            player.pause()
            commandCenterController.pause()
            delegate?.audioPlayer(self, didPause: playbackState)
        case .invalid:
            commandCenterController.stop()
            delegate?.audioPlayer(self, didBecomeInvalid: playbackState)
        case .pending:
            break
        }
    }
    
    private func configurePlayer(_ playerItems: [AVPlayerItem], _ playAtIndex: Int) {
        player.removeAllItems()
        playerItems.forEach { player.insert($0, after: nil) }
        // Immediately advance to the selected index
        (0..<playAtIndex).forEach { _ in player.advanceToNextItem() }
    }
        
    private func configureObserverHandlers() {
        playerObserver.timeUpdateHandler = { timeInSeconds in
            guard
                let currentPlayerDuration = self.currentPlayerItem?.duration.seconds,
                currentPlayerDuration.isFinite && !currentPlayerDuration.isNaN
            else { return }
            self.configureCommandCenter()
            self.delegate?.audioPlayer(self, didUpdateDuration: timeInSeconds, totalDuration: Int(currentPlayerDuration))
        }
        playerObserver.playerItemUpdateHandler = {
            if let playerItem = self.currentPlayerItem, let index = self.indexOfCurrentPlayerItem {
                self.delegate?.audioPlayer(self, didChangePlayerItem: playerItem, at: index)
                if self.isPlayerAtLastItem {
                    self.player.actionAtItemEnd = .pause
                } else {
                    self.player.actionAtItemEnd = .advance
                }
            }
            self.configureCommandCenter()
        }
    }
    
    private func configureCommandCenter() {
        if let indexOfCurrentPlayerItem = indexOfCurrentPlayerItem,
           let elapsedTime = currentPlayerItem?.currentTime().seconds,
           let totalDuration = currentPlayerItem?.asset.duration.seconds {
            let itemTitle = dataSource?.audioPlayer(self, shouldDisplayTitleAtIndex: indexOfCurrentPlayerItem) ?? ""
            let itemImage = dataSource?.audioPlayer(self, shouldDisplayRemoteImageAtIndex: indexOfCurrentPlayerItem)
            let remoteConfig = RemotePlayConfig(
                rate: player.rate, title: itemTitle, image: itemImage, totalDuration: totalDuration, currentDuration: elapsedTime
            )
            commandCenterController.configureNowPlayingInfoCenter(config: remoteConfig)
        }
    }
    
    private func configureCommandCenterHandlers() {
        commandCenterController.nextHandler = skipForward
        commandCenterController.previousHandler = skipBack
        commandCenterController.playHandler = {
            self.playbackState = .playing
        }
        commandCenterController.pauseHandler = {
            self.playbackState = .paused
        }
    }
}
