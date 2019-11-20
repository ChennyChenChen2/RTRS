//
//  ViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import MarqueeLabel

class RootTabController: UITabBarController {
    
    var playerView: TabBarPlayerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(showPlayerView), name: NSNotification.Name.PodcastManagerLoadedNewPod, object: nil)
    }
    
    @objc func showPlayerView() {
        let viewHeight: CGFloat = 50.0
        let view = TabBarPlayerView(frame: CGRect(x: 0, y: self.tabBar.frame.origin.y - viewHeight, width: self.view.frame.size.width, height: viewHeight))
        self.view.addSubview(view)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showPodVC))
        view.addGestureRecognizer(recognizer)
    }
        
    @objc func showPodVC() {
        if let vc = PodcastManager.shared.currentPodVC {
            self.present(vc, animated: true, completion: nil)
        }
    }
}

class TabBarPlayerView: UIView {
    var playPauseButton: UIButton?
    
    override init(frame: CGRect) {
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
        if let title = manager.title, let date = manager.dateString {
            let titleLabel = MarqueeLabel()
            titleLabel.text = "\(title) "
            titleLabel.textColor = .white
            titleLabel.font = Utils.defaultFontBold
            titleLabel.sizeToFit()
            titleLabel.frame.size.width = self.frame.size.width * 0.75
            titleLabel.frame = CGRect(x: 10, y: 5, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
            
            let dateLabel = MarqueeLabel()
            dateLabel.text = "\(date) "
            dateLabel.textColor = .white
            dateLabel.font = Utils.defaultFont
            dateLabel.sizeToFit()
            dateLabel.frame.size.width = self.frame.size.width * 0.75
            dateLabel.frame = CGRect(x: 10, y: titleLabel.bounds.origin.y + 10 + dateLabel.frame.size.height, width: dateLabel.frame.size.width, height: dateLabel.frame.size.height)
            
            self.playPauseButton = UIButton()
            self.playPauseButton?.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            self.playPauseButton?.frame = CGRect(x: self.frame.size.width - 35, y: (self.frame.size.height / 2) - 12, width: 25, height: 25)
            self.playPauseButton?.addTarget(self, action: #selector(playerViewPlayPauseAction), for: .touchUpInside)
            
            self.addSubview(titleLabel)
            self.addSubview(dateLabel)
            self.addSubview(self.playPauseButton!)
        }
    }
    
    @objc func playerViewPlayPauseAction() {
        if PodcastManager.shared.isPlaying {
            PodcastManager.shared.pause()
            self.playPauseButton?.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        } else {
            PodcastManager.shared.play()
            self.playPauseButton?.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        }
    }
}

