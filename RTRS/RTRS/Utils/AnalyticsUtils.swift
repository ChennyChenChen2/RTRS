//
//  AnalyticsUtils.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import FirebaseAnalytics

protocol LoggableViewController {
    func viewModelForLogging() -> RTRSViewModel?
}

class AnalyticsUtils {
    
    class func logScreenView(_ vc: LoggableViewController) {
        if let vm = vc.viewModelForLogging() {
            Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                AnalyticsParameterItemName: vm.pageName()
            ])
        }
    }

    class func logViewContentScreen() {
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemName: "Content View"
        ])
    }
    
    class func logViewAUMultiArticle() {
        
    }
    
    class func logViewMultiPod() {
        
    }
    
    class func logViewAUArticle() {
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemName: "Content View"
        ])
    }
    
    class func logError(_ vc: LoggableViewController) {
        Analytics.logEvent("Error", parameters: [
            AnalyticsParameterItemName: vc.viewModelForLogging()?.pageName(),
            "Source View Controller": vc,
        ])
    }
}
