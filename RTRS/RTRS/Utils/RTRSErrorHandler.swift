//
//  RTRSErrorHandler.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSErrorHandler {
    
    class func showNetworkError(in viewController: UIViewController, completion: (() -> ())?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Something went wrong. You hate to see it.", message: "Maybe your internet is as bad as AU's. Please try again later, or contact Kornblau if you suspect someone is sabotaging you.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                completion?()
            })
            alert.addAction(action)
            viewController.present(alert, animated: true, completion: nil)
        }
        
    }
}
