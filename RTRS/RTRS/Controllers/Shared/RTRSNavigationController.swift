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
        appearanceProxy.tintColor = .white
        appearanceProxy.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defaultNavBarCustomization()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func defaultNavBarCustomization() {
        self.navigationBar.backgroundColor = .black
        self.navigationBar.barTintColor = .black
        self.navigationBar.titleTextAttributes = [.font: Utils.defaultFontBold, NSAttributedString.Key.foregroundColor: UIColor.white]
    }
}
