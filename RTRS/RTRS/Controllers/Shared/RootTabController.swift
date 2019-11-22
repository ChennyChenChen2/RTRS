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
        
        var view: TabBarPlayerView
        if let tabPlayerView = PodcastManager.shared.tabPlayerView {
            view = tabPlayerView
        } else {
            view = TabBarPlayerView(frame: CGRect(x: 0, y: self.tabBar.frame.origin.y - viewHeight, width: self.view.frame.size.width, height: viewHeight))
            PodcastManager.shared.tabPlayerView = view
        }
        
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
