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
    case tooManyRequests
    case dataNotFound
    
    var alertTitle: String {
        switch self {
        case .network: return "Something went wrong. You hate to see it."
        case .dataNotAvailable: return "Data still loading! Trust the Process."
        case .tooManyRequests: return "Slow your roll!"
        case .dataNotFound: return "We couldn't find the content you were looking for"
        }
    }
    
    var alertMessage: String {
        switch self {
        case .network: return "Maybe your internet is as bad as AU's. Please try again later, or contact Kornblau if you suspect someone is sabotaging you."
        case .dataNotAvailable: return "The app is still downloading data, try again in a few seconds."
        case .tooManyRequests: return "You've requested a reload too quickly since the last one. Please wait at least one minute to prevent Squarespace from throttling your requests."
        case .dataNotFound: return "More than likely this is because something went wrong when we tried to fetch data from Squarespace. Please refresh the data by tapping the home screen icon, then try again."
        }
    }
}

class RTRSErrorHandler {
    
    // If nil is specified for viewController, display error in top VC
    class func showError(in viewController: UIViewController?, type: RTRSError, completion: (() -> ())?) {
        DispatchQueue.main.async {
            let vc = viewController ?? (UIApplication.shared.keyWindow?.rootViewController as? RTRSNavigationController)?.topViewController
        
            if let theVC = vc {
                let alert = UIAlertController(title: type.alertTitle, message: type.alertMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    completion?()
                })
                alert.addAction(action)
                theVC.present(alert, animated: true, completion: nil)
                
                if let logVC = theVC as? LoggableViewController {
                    AnalyticsUtils.logError(logVC, error: type)
                }
            }
        }
    }
}
