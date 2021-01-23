//
//  ViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import MarqueeLabel

class RootTabController: UITabBarController, UITabBarControllerDelegate {
    
    var playerView: TabBarPlayerView?
    
    private let headNames = ["Hinkie", "Brett", "Joel", "Dario", "Roco", "TJ"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleTabBar()
        
        self.delegate = self
        
        if let contentItem = self.tabBar.items?[1] {
            let index = Int.random(in: 0..<headNames.count)
            contentItem.image = UIImage(named: headNames[index])
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(styleTabBar), name: NSNotification.Name.darkModeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showPlayerView), name: NSNotification.Name.PodcastManagerLoadedNewPod, object: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.navigationController?.preferredStatusBarStyle ?? .default
    }
    
    @objc func styleTabBar() {
        DispatchQueue.main.async {
            let barAppearance = UITabBar.appearance(whenContainedInInstancesOf: [RootTabController.self])
            barAppearance.barTintColor = AppStyles.foregroundColor
            
            let itemAppearance = UITabBarItem.appearance(whenContainedInInstancesOf: [UITabBar.self])
            itemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor], for: .normal)
            itemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], for: .selected)
            
            if let items = self.tabBar.items {
                for item in items {
                    item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor], for: .normal)
                    item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], for: .selected)
                }
            }
            
            self.tabBar.backgroundColor = AppStyles.backgroundColor
            self.tabBar.barTintColor = AppStyles.backgroundColor
            self.playerView?.layoutSubviews()
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    @objc func showPlayerView() {
        if let view = self.playerView {
            view.removeFromSuperview()
            self.playerView = nil
            
            for subview in self.view.subviews {
                if subview is TabBarPlayerView {
                    subview.removeFromSuperview()
                }
            }
        }
        
        let viewHeight: CGFloat = 50.0
        
        self.playerView = TabBarPlayerView(frame: CGRect(x: 0, y: self.tabBar.frame.origin.y - viewHeight, width: self.view.frame.size.width, height: viewHeight))
        PodcastManager.shared.tabPlayerView = self.playerView
        
        if let view = self.playerView {
            self.view.addSubview(view)
            
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(showPodVC))
            view.addGestureRecognizer(recognizer)
        }
    }
        
    @objc func showPodVC() {
        if let vc = PodcastManager.shared.currentPodVC {
            vc.displayedViaTabView = true
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let vc = viewController as? RTRSNavigationController,
           let topVC = vc.topViewController {
            if let tableView = topVC.view as? UITableView {
                tableView.setContentOffset(CGPoint(x: 0, y: -tableView.safeAreaInsets.top), animated: true)
            }
        }
        
        return true
    }
}
