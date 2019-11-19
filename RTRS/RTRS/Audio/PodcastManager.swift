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

class PodcastManager: NSObject {

    static let shared = PodcastManager()
    override private init() {
        super.init()
    }
    
    fileprivate var itemObserver: KeyValueObserver<AVPlayerItem>?
    fileprivate var playerObserver: KeyValueObserver<AVPlayer>?
    fileprivate var player: AVPlayer = AVPlayer()
    weak var delegate: PodcastManagerDelegate?
    var title: String?
    var rate: Float = 1.0 {
        didSet {
            self.setRate(rate: self.rate)
        }
    }
    
    var duration: CMTime?
    
    func play() {
        self.player.play()
        self.delegate?.podcastDidBeginPlay()
    }
    
    func pause() {
        self.player.pause()
    }
    
    func skip(delta: Double) {
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTimeMake(value: Int64(delta), timescale: 1)
        player.seek(to: newTime)
    }
    
    func seek(location: Double) {
        if let item = self.player.currentItem {
            let seekTime = location * item.duration.seconds
            let newTime = CMTimeMake(value: Int64(seekTime), timescale: 1)
            player.seek(to: newTime)
            self.delegate?.podcastTimeDidUpdate(elapsed: newTime, position: Float(location))
        }
    }
    
    fileprivate func setRate(rate: Float) {
        self.player.rate = rate
    }
    
    func preparePlayer(title: String, url: URL, image: UIImage) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
        
        self.player.pause()
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player.automaticallyWaitsToMinimizeStalling = false
        
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "The Rights to Ricky Sanchez"
//        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 25, height: 25), requestHandler: { (size) -> UIImage in
//            return image
//        })
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        self.configureCommandCenter()
        
        self.itemObserver = KeyValueObserver(observee: item)
        self.itemObserver?.addObserver(forKeyPath: "status", options: [.old, .new], closure: { [weak self] (item, changes) in
            if let weakSelf = self, let newStatusInt = changes?[.newKey] as? Int, let newStatus = AVPlayerItem.Status(rawValue: newStatusInt) {
                if newStatus == .readyToPlay {
                    if let item = weakSelf.player.currentItem {
                        weakSelf.delegate?.podcastReadyToPlay(duration: item.duration)
                        weakSelf.duration = item.duration
                    }
                }
            }
        })
        
        self.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil, using: { [weak self] (time) in
            if let weakSelf = self, let item = weakSelf.player.currentItem {
                let duration = Float(item.duration.seconds)
                weakSelf.delegate?.podcastTimeDidUpdate(elapsed: time, position: Float(time.seconds) / duration)
                if time.seconds == item.duration.seconds {
                    weakSelf.delegate?.podcastDidFinish()
                }
            }
        })
    }
    
    fileprivate func configureCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
/*         commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self else { return .commandFailed }
            
            if weakSelf.player.rate > 0.0 {
                weakSelf.skip(delta: 15.0)
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let weakSelf = self else { return .commandFailed }
            
            if weakSelf.player.rate > 0.0 {
                weakSelf.skip(delta: -15.0)
                return .success
            }
            return .commandFailed
        }
 
 */

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let weakSelf = self else { return .commandFailed }
            if weakSelf.rate == 0.0 {
                weakSelf.play()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let weakSelf = self else { return .commandFailed }
            if weakSelf.rate == 1.0 {
                weakSelf.pause()
                return .success
            }
            return .commandFailed
        }
    }
}

protocol PodcastManagerDelegate: NSObject {
    func podcastReadyToPlay(duration: CMTime)
    func podcastDidFinish()
    func podcastDidBeginPlay()
    func podcastTimeDidUpdate(elapsed: CMTime, position: Float)
}
