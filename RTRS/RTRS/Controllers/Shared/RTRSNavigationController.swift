//
//  RTRSNavigationController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/15/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [RTRSNavigationController.self])
        appearanceProxy.tintColor = AppStyles.foregroundColor
        appearanceProxy.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        
        NotificationCenter.default.addObserver(self, selector: #selector(styleForDarkMode), name: .darkModeUpdated, object: nil)
    }
    
    @objc private func styleForDarkMode() {
        self.setNeedsStatusBarAppearanceUpdate()
        defaultNavBarCustomization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defaultNavBarCustomization()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return AppStyles.darkModeEnabled ? .lightContent : .darkContent
        } else {
            return AppStyles.darkModeEnabled ? .lightContent : .default
        }
    }
    
    fileprivate func defaultNavBarCustomization() {
        self.navigationBar.backgroundColor = AppStyles.backgroundColor
        self.navigationBar.barTintColor = AppStyles.backgroundColor
        self.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationBar.titleTextAttributes = [.font: Utils.defaultFontBold, NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        self.setNeedsStatusBarAppearanceUpdate()
    }
}
