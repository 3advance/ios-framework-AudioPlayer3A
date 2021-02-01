import AVFoundation

public class AudioPlayer3A {
    public static let shared = AudioPlayer3A()
    
    // MARK: - Dependencies
    weak var delegate: AudioPlayerDelegate?
    weak var dataSource: AudioPlayerDataSource?
    
    private let audioSession = AVAudioSession.sharedInstance()
    private let playerObserver = AudioPlayer3AStateObserver()
    private let controlCenterController = AudioControlCenterController()
    
    // MARK: - Properties
    private var looper: AVPlayerLooper?
    private let player: AVQueuePlayer = AVQueuePlayer()
    private(set) var playerQueue: [AVPlayerItem] = []
    public var audioCategoryOptions: AVAudioSession.CategoryOptions = [
        .mixWithOthers, .allowAirPlay, .defaultToSpeaker
    ]

    // MARK: - State
    public private(set) var playbackState: AdvancePlaybackState = .pending {
        didSet {
            handlePlaybackStateChange()
        }
    }
    public var isPaused: Bool {
        return player.rate == 0
    }
    public private(set) var isRepeatEnabled: Bool = false {
        didSet {
            if isRepeatEnabled {
                looper = AVPlayerLooper(player: player, templateItem: currentPlayerItem!)
            } else {
                looper?.disableLooping()
            }
        }
    }
    public var currentPlayerItem: AVPlayerItem? {
        return player.currentItem
    }
    public var indexOfCurrentPlayerItem: Int? {
        guard let currentItem = currentPlayerItem else { return nil }
        return playerQueue.firstIndex(of: currentItem)
    }
    public var isPlayerAtLastItem: Bool {
        return playerQueue.count-1 == indexOfCurrentPlayerItem
    }
    
    // MARK: - Setup
    /// Loads the player queue and configures the player given URLs.
    /// - Parameters:
    ///   - assetURLs: Array of audio URLs.
    ///   - playAtIndex: The starting index of the player.
    /// - Throws: Error thrown from the audio session setup/configuration.
    public func loadPlayerItems(from assetURLs: [URL], playAtIndex: Int = 0) throws {
        let isPlayIndexWithinRange = playAtIndex >= 0 && playAtIndex < assetURLs.count
        if !isPlayIndexWithinRange { throw NSError(domain: "Invalid play index", code: -1, userInfo: nil) }
        try audioSession.setCategory(
            AVAudioSession.Category.playback,
            mode: AVAudioSession.Mode.default,
            options: audioCategoryOptions
        )
        try AVAudioSession.sharedInstance().setActive(true)
        print("Audio Session is Active")
        let avAssets = assetURLs.map{ AVAsset(url: $0) }
        let playerItems = avAssets.map{ AVPlayerItem(asset: $0) }
        playerQueue = playerItems
        configurePlayer(playerItems, playAtIndex)
        configureObserverHandlers()
        configureControlCenterHandlers()
        playerObserver.observeTimeChanges(in: player)
        playerObserver.observeCurrentItemChanges(in: player)
    }
    
    // MARK: - Controls
    /// Toggles the current player item playback state. If you did not initially call loadPlayerItems, this method will set the playback state to invalid.
    public func play() {
        if playerQueue.isEmpty { playbackState = .invalid; return }
        controlCenterController.setup()
        configureCommandCenter()
        playbackState = isPaused ? .playing : .paused
        if let playerItem = currentPlayerItem, let index = indexOfCurrentPlayerItem {
            delegate?.audioPlayer(self, didChangePlayerItem: playerItem, at: index)
        }
    }
    
    /// Terminates the player removing observers and emptying the player queue.
    public func stop() {
        player.pause()
        player.removeAllItems()
        playerQueue.removeAll()
        playbackState = .invalid
        playerObserver.removeTimeObserver(in: player)
        try? audioSession.setActive(false)
        controlCenterController.clearRemoteNowPlayingInfoCenter()
    }
    
    public func goBackFifteenSeconds() {
        let currentTime = player.currentTime().seconds
        guard currentTime != 0 else { return }
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: currentTime - 15, preferredTimescale: timeScale))
    }
    
    public func goForwardFifteenSeconds() {
        let currentTime = player.currentTime().seconds
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: currentTime + 15, preferredTimescale: timeScale))
    }
    
    public func seek(to value: Float) {
        let newTime = Double(value)
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: timeScale))
    }
    
    @discardableResult public  func toggleLooping() -> Bool {
        isRepeatEnabled = !isRepeatEnabled
        return isRepeatEnabled
    }
    
    public func skipForward() {
        if !isPlayerAtLastItem {
            player.advanceToNextItem()
        }
    }
    
    public func skipBack() {
        if let indexOfCurrentPlayerItem = indexOfCurrentPlayerItem, indexOfCurrentPlayerItem > 0 {
            configurePlayer(playerQueue, indexOfCurrentPlayerItem - 1)
        }
        currentPlayerItem?.seek(to: .zero, completionHandler: nil)
    }
}

// MARK: - Private Helpers
extension AudioPlayer3A {
    private func handlePlaybackStateChange() {
        switch playbackState {
        case .playing:
            player.play()
            controlCenterController.play()
            delegate?.audioPlayer(self, didPlay: playbackState)
        case .paused:
            player.pause()
            controlCenterController.pause()
            delegate?.audioPlayer(self, didPause: playbackState)
        case .invalid:
            controlCenterController.stop()
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
            controlCenterController.configureNowPlayingInfoCenter(config: remoteConfig)
        }
    }
    
    private func configureControlCenterHandlers() {
        controlCenterController.nextHandler = skipForward
        controlCenterController.previousHandler = skipBack
        controlCenterController.playHandler = {
            self.playbackState = .playing
        }
        controlCenterController.pauseHandler = {
            self.playbackState = .paused
        }
    }
}
