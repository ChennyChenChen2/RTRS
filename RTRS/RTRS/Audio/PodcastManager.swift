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

class PodcastManager: NSObject {

    static let shared = PodcastManager()
    override private init() {
        super.init()
        self.configureCommandCenter()
    }
    
    fileprivate var itemObserver: KeyValueObserver<AVPlayerItem>?
    fileprivate var playerObserver: KeyValueObserver<AVPlayer>?
    fileprivate var player: AVPlayer?
    
    weak var delegate: PodcastManagerDelegate?
    var title: String?
    var dateString: String?
    var currentPodVC: PodcastPlayerViewController?
    var tabPlayerView: TabBarPlayerView?
    
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
        self.player?.play()
        self.delegate?.podcastDidBeginPlay()
        if let title = self.title {
            AnalyticsUtils.logPodBegan(title)
        }
        self.tabPlayerView?.playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
    }
    
    func pause() {
        self.player?.pause()
        self.delegate?.podcastDidPause()
        self.tabPlayerView?.playPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
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
    }
    
    func preparePlayer(title: String, url: URL, image: UIImage, dateString: String) {
        self.title = title
        self.dateString = dateString
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
        
        self.player?.pause()
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        
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
                }
            }
        })
        
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
        
        NotificationCenter.default.post(name: .PodcastManagerLoadedNewPod, object: nil)
    }
    
    fileprivate func configureCommandCenter() {
        
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

class TabBarPlayerView: UIView {
    fileprivate var playPauseButton: UIButton!
    fileprivate var titleLabel: MarqueeLabel!
    fileprivate var dateLabel: MarqueeLabel!
    
    override init(frame: CGRect) {
        self.playPauseButton = UIButton()
        self.titleLabel = MarqueeLabel()
        self.dateLabel = MarqueeLabel()
        
        super.init(frame: frame)
        self.backgroundColor = .black
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.layer.borderWidth = 1.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let manager = PodcastManager.shared
        if let title = manager.title, let dateString = manager.dateString {
            for subview in self.subviews {
                subview.removeFromSuperview()
            }
            
            self.titleLabel = MarqueeLabel()
            self.titleLabel.text = "\(title). "
            self.titleLabel.textColor = .white
            self.titleLabel.font = Utils.defaultFontBold
            self.titleLabel.sizeToFit()
            self.titleLabel.frame.size.width = self.frame.size.width * 0.75
            self.titleLabel.frame = CGRect(x: 10, y: 5, width: self.titleLabel.frame.size.width, height: self.titleLabel.frame.size.height)
            
            self.dateLabel = MarqueeLabel()
            self.dateLabel.text = dateString
            self.dateLabel.textColor = .white
            self.dateLabel.font = Utils.defaultFont
            self.dateLabel.sizeToFit()
            self.dateLabel.frame.size.width = self.frame.size.width * 0.75
            self.dateLabel.frame = CGRect(x: 10, y: self.titleLabel.bounds.origin.y + 10 + self.dateLabel.frame.size.height, width: self.dateLabel.frame.size.width, height: self.dateLabel.frame.size.height)
            
            self.playPauseButton = UIButton()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            self.playPauseButton.frame = CGRect(x: self.frame.size.width - 50, y: (self.frame.size.height / 2) - 12, width: 25, height: 25)
            self.playPauseButton.addTarget(self, action: #selector(playerViewPlayPauseAction), for: .touchUpInside)
            
            self.addSubview(self.titleLabel)
            self.addSubview(self.dateLabel)
            self.addSubview(self.playPauseButton)
        }
    }
    
    @objc func playerViewPlayPauseAction() {
        if PodcastManager.shared.isPlaying {
            PodcastManager.shared.pause()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        } else {
            PodcastManager.shared.play()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        }
    }
}
