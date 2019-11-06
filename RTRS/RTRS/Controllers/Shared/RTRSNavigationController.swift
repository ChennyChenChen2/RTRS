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
        
        // Do any additional setup after loading the view.
    }
    
//    override var navigationBar: UINavigationBar {
//        return RTRSNavigationBar()
//    }
    
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
        self.navigationBar.titleTextAttributes = [.font: Utils.defaultFontBold]
        
    }
}

extension UINavigationController {

}


extension UINavigationItem {
    func customizeNavBarForHome() {
        DispatchQueue.main.async {
//            let imageView = UIImageView(image: #imageLiteral(resourceName: "Top-Nav-Image"))
//            imageView.contentMode = .scaleAspectFit
//            imageView.sizeToFit()
//            self.titleView = imageView
//            self.titleView?.sizeToFit()
//            self.title = nil
            
        }
    }
}
