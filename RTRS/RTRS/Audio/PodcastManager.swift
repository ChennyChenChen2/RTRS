//
//  PodcastManager.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import MarqueeLabel

protocol PodcastManagerDelegate: NSObject {
    func podcastReadyToPlay(duration: CMTime)
    func podcastDidFinish()
    func podcastDidBeginPlay()
    func podcastDidPause()
    func podcastTimeDidUpdate(elapsed: CMTime, position: Float)
}

extension Notification.Name {
    static let PodcastManagerLoadedNewPod = Notification.Name("PodcastManagerLoadedNewPod")
    static let PodcastManagerDidPlay = Notification.Name("PodcastManagerDidPlay")
    static let PodcastManagerDidPause = Notification.Name("PodcastManagerDidPause")
}

class PodcastManager: NSObject {

    static let shared = PodcastManager()
    override private init() {
        super.init()
        self.configure()
    }
    
    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    fileprivate var itemObserver: KeyValueObserver<AVPlayerItem>?
    fileprivate var playerObserver: KeyValueObserver<AVPlayer>?
    fileprivate var player: AVQueuePlayer?
    
    weak var delegate: PodcastManagerDelegate?
    var title: String?
    var dateString: String?
    var currentPodVC: PodcastPlayerViewController?
    var tabPlayerView: TabBarPlayerView?
    
    var playerViewIsShowing: Bool {
        return self.tabPlayerView != nil
    }
    
    var isPlaying: Bool {
        if let player = self.player {
            return player.rate > 0
        } else {
            return false
        }
    }
    
    var rate: Float = 1.0 {
        didSet {
            self.setRate(rate: self.rate)
        }
    }
    
    var duration: CMTime?
    
    func play() {
        self.player?.playImmediately(atRate: self.rate)
        self.delegate?.podcastDidBeginPlay()
        if let title = self.title {
            AnalyticsUtils.logPodBegan(title)
        }
        
        NotificationCenter.default.post(name: .PodcastManagerDidPlay, object: nil)
    }
    
    func pause() {
        self.player?.pause()
        self.delegate?.podcastDidPause()
        
        NotificationCenter.default.post(name: .PodcastManagerDidPause, object: nil)
    }
    
    func skip(delta: Double) {
        if let currentTime = self.player?.currentTime() {
            let newTime = currentTime + CMTimeMake(value: Int64(delta), timescale: 1)
            self.player?.seek(to: newTime)
        }
    }
    
    func seek(location: Double) {
        if let item = self.player?.currentItem {
            let seekTime = location * item.duration.seconds
            let newTime = CMTimeMake(value: Int64(seekTime), timescale: 1)
            self.player?.seek(to: newTime)
            self.delegate?.podcastTimeDidUpdate(elapsed: newTime, position: Float(location))
        }
    }
    
    fileprivate func setRate(rate: Float) {
        self.player?.rate = rate
        if (rate > 0.0) {
            self.delegate?.podcastDidBeginPlay()
        }
    }
    
    func preparePlayer(title: String, url: URL, dateString: String) {
        self.title = title
        self.dateString = dateString
        
        self.player?.pause()
        let item = AVPlayerItem(url: url)
        self.player = AVQueuePlayer(playerItem: item)
        
        self.itemObserver = KeyValueObserver(observee: item)
        self.itemObserver?.addObserver(forKeyPath: "status", options: [.old, .new], closure: { [weak self] (item, changes) in
            if let weakSelf = self, let newStatusInt = changes?[.newKey] as? Int, let newStatus = AVPlayerItem.Status(rawValue: newStatusInt) {
                if newStatus == .readyToPlay {
                    if let item = weakSelf.player?.currentItem {
                        weakSelf.delegate?.podcastReadyToPlay(duration: item.duration)
                        weakSelf.duration = item.duration
                    }
                }
            }
        })
        
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil, using: { [weak self] (time) in
            if let weakSelf = self, let item = weakSelf.player?.currentItem, let player = weakSelf.player {
                let duration = Float(item.duration.seconds)
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = item.currentTime().seconds
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = (item.currentTime().seconds / item.asset.duration.seconds) as NSNumber
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
                weakSelf.delegate?.podcastTimeDidUpdate(elapsed: time, position: Float(time.seconds) / duration)
                if time.seconds == item.duration.seconds {
                    if let title = weakSelf.title {
                        AnalyticsUtils.logPodFinished(title)
                    }
                    
                    weakSelf.delegate?.podcastDidFinish()
                    AnalyticsUtils.logPodFinished(title)
                }
            }
        })
        
        self.player?.actionAtItemEnd = .advance
        
        NotificationCenter.default.post(name: .PodcastManagerLoadedNewPod, object: nil)
    }
    
    func configureNowPlayingInfo(image: UIImage) {
        guard let player = self.player, let playerItem = player.currentItem else { return }
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "The Rights to Ricky Sanchez"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: image.size.width, height: image.size.height), requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func configure() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self else { return .commandFailed }
            
            if let player = weakSelf.player, player.rate > 0.0 {
                weakSelf.skip(delta: 10.0)
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self else { return .commandFailed }
            
            if let player = weakSelf.player, player.rate > 0.0 {
                weakSelf.skip(delta: -10.0)
                return .success
            }
            return .commandFailed
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let weakSelf = self else { return .commandFailed }
            weakSelf.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let weakSelf = self else { return .commandFailed }
            weakSelf.pause()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self, let playbackEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            if let currentItem = weakSelf.player?.currentItem {
                let location = playbackEvent.positionTime / currentItem.duration.seconds
                print("""
                ********
                ATTEMPTED TO SEEK:
                LOCATION: \(location)
                NEW POSITION: \(playbackEvent.positionTime)
                TOTAL DURATION: \(currentItem.duration.seconds)
                ********
                """)
                weakSelf.seek(location: location)
                return .success
            }

            return .commandFailed
        }
        
        // TODO: Not showing for some reason...
        commandCenter.changePlaybackRateCommand.isEnabled = true
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.8, 1.0, 1.25, 1.5, 2.0, 3.0]
        commandCenter.changePlaybackRateCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self, let playbackEvent = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            weakSelf.setRate(rate: playbackEvent.playbackRate)

            return .success
        }
    }
}

class TabBarPlayerView: UIView {
    fileprivate var playPauseButton: UIButton!
    fileprivate var titleLabel: MarqueeLabel!
    fileprivate var dateLabel: MarqueeLabel!
    
    override init(frame: CGRect) {
        self.playPauseButton = UIButton()
        self.titleLabel = MarqueeLabel()
        self.dateLabel = MarqueeLabel()
        
        super.init(frame: frame)
        self.backgroundColor = AppStyles.backgroundColor
        self.layer.borderColor = AppStyles.foregroundColor.cgColor
        self.layer.borderWidth = 1.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayPauseButton), name: .PodcastManagerDidPlay, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayPauseButton), name: .PodcastManagerDidPause, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let manager = PodcastManager.shared
        
        self.backgroundColor = AppStyles.backgroundColor
        self.layer.borderColor = AppStyles.foregroundColor.cgColor
        if let title = manager.title, let dateString = manager.dateString {
            for subview in self.subviews {
                subview.removeFromSuperview()
            }
            
            self.titleLabel = MarqueeLabel()
            self.titleLabel.text = "\(title). "
            self.titleLabel.textColor = AppStyles.foregroundColor
            self.titleLabel.font = Utils.defaultFontBold
            self.titleLabel.sizeToFit()
            self.titleLabel.frame.size.width = self.frame.size.width * 0.75
            self.titleLabel.frame = CGRect(x: 10, y: 5, width: self.titleLabel.frame.size.width, height: self.titleLabel.frame.size.height)
            
            self.dateLabel = MarqueeLabel()
            self.dateLabel.text = dateString
            self.dateLabel.textColor = AppStyles.foregroundColor
            self.dateLabel.font = Utils.defaultFont
            self.dateLabel.sizeToFit()
            self.dateLabel.frame.size.width = self.frame.size.width * 0.75
            self.dateLabel.frame = CGRect(x: 10, y: self.titleLabel.bounds.origin.y + 10 + self.dateLabel.frame.size.height, width: self.dateLabel.frame.size.width, height: self.dateLabel.frame.size.height)
            
            self.playPauseButton = UIButton()
            self.playPauseButton.setImage(PodcastManager.shared.isPlaying ? #imageLiteral(resourceName: "Pause") : #imageLiteral(resourceName: "Play"), for: .normal)
            self.playPauseButton.frame = CGRect(x: self.frame.size.width - 50, y: (self.frame.size.height / 2) - 12, width: 25, height: 25)
            self.playPauseButton.addTarget(self, action: #selector(playerViewPlayPauseAction), for: .touchUpInside)
            self.playPauseButton.tintColor = AppStyles.foregroundColor
            
            self.addSubview(self.titleLabel)
            self.addSubview(self.dateLabel)
            self.addSubview(self.playPauseButton)
        }
    }
    
    @objc func playerViewPlayPauseAction() {
        if PodcastManager.shared.isPlaying {
            PodcastManager.shared.pause()
        } else {
            PodcastManager.shared.play()
        }
        
        self.updatePlayPauseButton()
    }
    
    @objc private func updatePlayPauseButton() {
        if PodcastManager.shared.isPlaying {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        } else {
            self.playPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        }
    }
}
