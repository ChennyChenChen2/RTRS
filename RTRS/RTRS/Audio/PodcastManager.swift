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
    override private init() {}
    fileprivate let viewModel = RTRSNavigation.shared.viewModel(for: .podSource)
    fileprivate var itemObserver: KeyValueObserver<AVPlayerItem>?
    fileprivate var playerObserver: KeyValueObserver<AVPlayer>?
    weak var delegate: PodcastManagerDelegate?
    var player: AVPlayer?
    var rate: Float = 1.0 {
        didSet {
            self.setRate(rate: self.rate)
        }
    }
    
    func skip(delta: Double) {
        guard let player = self.player else { return }
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTimeMake(value: Int64(delta), timescale: 1)
        player.seek(to: newTime)
    }
    
    func seek(location: Double) {
        if let player = self.player, let item = player.currentItem {
//            let seekTime = (location / item.duration.seconds) * item.duration.seconds
            let newTime = CMTimeMake(value: Int64(location), timescale: 1)
            player.seek(to: newTime)
        }
    }
    
    fileprivate func setRate(rate: Float) {
        if let player = self.player {
            player.rate = rate
        }
    }
    
    func preparePlayer(title: String, url: URL, image: UIImage) {
        self.player?.pause()
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player?.automaticallyWaitsToMinimizeStalling = false
        
        self.itemObserver = KeyValueObserver(observee: item)
        self.itemObserver?.addObserver(forKeyPath: "status", options: [.old, .new], closure: { [weak self] (item, changes) in
            if let weakSelf = self, let newStatusInt = changes?[.newKey] as? Int, let newStatus = AVPlayerItem.Status(rawValue: newStatusInt) {
                if newStatus == .readyToPlay {
                    if let player = weakSelf.player, let item = player.currentItem {
                        weakSelf.delegate?.podcastReadyToPlay(duration: item.duration)
                    }
                }
            }
        })
        
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil, using: { [weak self] (time) in
            if let weakSelf = self, let item = weakSelf.player?.currentItem {
                let duration = Float(item.duration.seconds)
                weakSelf.delegate?.podcastTimeDidUpdate(elapsed: time, position: Float(time.seconds) / duration)
            }
        })
        
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "The Rights to Ricky Sanchez"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 25, height: 25), requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
}

protocol PodcastManagerDelegate: NSObject {
    func podcastReadyToPlay(duration: CMTime)
    func podcastTimeDidUpdate(elapsed: CMTime, position: Float)
}
