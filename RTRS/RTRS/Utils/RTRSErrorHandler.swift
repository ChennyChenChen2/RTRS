//
//  RTRSErrorHandler.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

enum RTRSError: Error {
    case network
    case dataNotAvailable
    
    var alertTitle: String {
        switch self {
        case .network: return "Something went wrong. You hate to see it."
        case .dataNotAvailable: return "Data still loading! Trust the Process."
        }
    }
    
    var alertMessage: String {
        switch self {
        case .network: return "Maybe your internet is as bad as AU's. Please try again later, or contact Kornblau if you suspect someone is sabotaging you."
        case .dataNotAvailable: return "The app is still downloading data, try again in a few seconds."
        }
    }
}

class RTRSErrorHandler {
    
    // If nil is specified for viewController, display error in top VC
    class func showError(in viewController: UIViewController?, type: RTRSError, completion: (() -> ())?) {
        let vc = viewController ?? (UIApplication.shared.keyWindow?.rootViewController as? RTRSNavigationController)?.topViewController
        
        if let theVC = vc {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: type.alertTitle, message: type.alertMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    completion?()
                })
                alert.addAction(action)
                theVC.present(alert, animated: true, completion: nil)
            }
        }
    }
}
