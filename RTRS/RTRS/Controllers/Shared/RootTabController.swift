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
    
//    var playerView: UIView {
//
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(showPlayerView), name: NSNotification.Name.PodcastManagerLoadedNewPod, object: nil)
    }
    
    @objc func showPlayerView() {
        let manager = PodcastManager.shared
        if let title = manager.title, let date = manager.dateString {
            let viewHeight: CGFloat = 50.0
            let view = UIView(frame: CGRect(x: 0, y: self.tabBar.frame.origin.y - viewHeight, width: self.view.frame.size.width, height: viewHeight))
            view.backgroundColor = .black
            view.layer.borderColor = UIColor.darkGray.cgColor
            view.layer.borderWidth = 1.0
            self.view.addSubview(view)
            
            let titleLabel = MarqueeLabel()
            titleLabel.text = "\(title) "
            titleLabel.textColor = .white
            titleLabel.font = Utils.defaultFontBold
            titleLabel.sizeToFit()
            titleLabel.frame.size.width = view.frame.size.width * 0.75
            titleLabel.frame = CGRect(x: (view.bounds.size.width / 2) - (titleLabel.bounds.size.width / 2), y: 5, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
            
            let dateLabel = MarqueeLabel()
            dateLabel.text = "\(date) "
            dateLabel.textColor = .white
            dateLabel.font = Utils.defaultFont
            dateLabel.sizeToFit()
            dateLabel.frame.size.width = view.frame.size.width * 0.75
            dateLabel.frame = CGRect(x: (view.bounds.size.width / 2) - (dateLabel.bounds.size.width / 2), y: titleLabel.bounds.origin.y + 5 + dateLabel.frame.size.height, width: dateLabel.frame.size.width, height: dateLabel.frame.size.height)
            
            view.addSubview(titleLabel)
            view.addSubview(dateLabel)
            
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(showPodVC))
            view.addGestureRecognizer(recognizer)
        }
    }
    
    @objc func showPodVC() {
        if let vc = PodcastManager.shared.currentPodVC {
            self.present(vc, animated: true, completion: nil)
        }
    }
}

