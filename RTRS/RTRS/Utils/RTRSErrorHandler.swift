//
//  RTRSErrorHandler.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSErrorHandler {
    
    // If nil is specified for viewController, display error in top VC
    class func showNetworkError(in viewController: UIViewController?, completion: (() -> ())?) {
        let vc = viewController ?? (UIApplication.shared.keyWindow?.rootViewController as? RTRSNavigationController)?.topViewController
        
        if let theVC = vc {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Something went wrong. You hate to see it.", message: "Maybe your internet is as bad as AU's. Please try again later, or contact Kornblau if you suspect someone is sabotaging you.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    completion?()
                })
                alert.addAction(action)
                theVC.present(alert, animated: true, completion: nil)
            }
        }
    }
}
