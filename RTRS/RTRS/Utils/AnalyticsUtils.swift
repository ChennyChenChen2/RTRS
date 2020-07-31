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
    
    class func logViewProcessPup(_ name: String) {
        Analytics.logEvent(name.analyticsString, parameters: [
            AnalyticsParameterItemName: "ProcessPup",
            AnalyticsParameterItemID: "Process Pup"
        ])
    }
    
    class func logPodBegan(_ title: String) {
        Analytics.logEvent(title.analyticsString, parameters: [
            AnalyticsParameterItemName: "PodBegan",
            AnalyticsParameterItemID: "PodBegan"
        ])
    }
    
    class func logPodFinished(_ title: String) {
        Analytics.logEvent(title.analyticsString, parameters: [
            AnalyticsParameterItemName: "PodFinished",
            AnalyticsParameterItemID: "PodFinished"
        ])
    }
    
    class func logViewArticle(_ title: String, column: String) {
        Analytics.logEvent(title.analyticsString, parameters: [
            AnalyticsParameterItemName: column,
            AnalyticsParameterItemID: column
        ])
    }
    
    class func logError(_ vc: LoggableViewController) {
        Analytics.logEvent("Error", parameters: [
            AnalyticsParameterItemName: vc.viewModelForLogging()!.pageName(),
            "Source View Controller": vc,
        ])
    }
}

extension String {
    var analyticsString: String {
        let filtered = self.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        
        
        return String(filtered.prefix(40))
    
    }
}
