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

class PodcastManager {

    static let shared = PodcastManager()
    private init() {
        initialize()
    }
    fileprivate let viewModel = RTRSNavigation.shared.viewModel(for: .podSource)
    var player: AVPlayer?
    
    func initialize() {
        
    }
    
    func setRate(rate: Float) {
        if let player = self.player {
            player.setRate(rate, time: .zero, atHostTime: .positiveInfinity)
            
            
        }
    }
    
    func preparePlayer(title: String, url: URL, image: UIImage) {
        self.player?.pause()
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "The Rights to Ricky Sanchez"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 25, height: 25), requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        self.player?.play()
    }
}
