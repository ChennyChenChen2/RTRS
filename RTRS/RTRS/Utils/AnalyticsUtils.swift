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
    
    class func logRefreshTriggered() {
        Analytics.logEvent("RefreshTriggered".analyticsString, parameters: [
            AnalyticsParameterItemName: "RefreshTriggered",
            AnalyticsParameterItemID: "RefreshTriggered"
        ])
    }
    
    class func logScreenView(_ vc: LoggableViewController) {
        if let vm = vc.viewModelForLogging() {
            Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                AnalyticsParameterItemName: vm.pageName()
            ])
        }
    }
    
    class func logScreenView(_ name: String) {
        Analytics.logEvent("ScreenView", parameters: [
            AnalyticsParameterItemName: name.analyticsString,
            AnalyticsParameterItemID: name.analyticsString
        ])
    }
    
    class func logExternalWebView(_ title: String) {
        Analytics.logEvent("ExternalWebView", parameters: [
            AnalyticsParameterItemName: title.analyticsString,
            AnalyticsParameterItemID: title.analyticsString
        ])
    }
    
    class func logViewGalleryEntry(_ name: String) {
        Analytics.logEvent("GalleryEntryView", parameters: [
            AnalyticsParameterItemName: name.analyticsString,
            AnalyticsParameterItemID: name.analyticsString
        ])
    }
    
    class func logYoutubeButtonPressed(_ podTitle: String) {
        Analytics.logEvent("YoutubePressed", parameters: [
            AnalyticsParameterItemName: podTitle.analyticsString,
            AnalyticsParameterItemID: podTitle.analyticsString
        ])
    }
    
    class func logPodBegan(_ title: String) {
        Analytics.logEvent("PodBegan", parameters: [
            AnalyticsParameterItemName: title.analyticsString,
            AnalyticsParameterItemID: title.analyticsString
        ])
    }
    
    class func logPodFinished(_ title: String) {
        Analytics.logEvent("PodFinished", parameters: [
            AnalyticsParameterItemName: title.analyticsString,
            AnalyticsParameterItemID: "PodFinished"
        ])
    }
    
    class func logViewArticle(_ title: String, column: String) {
        Analytics.logEvent("ViewArticle", parameters: [
            AnalyticsParameterItemName: title.analyticsString,
            AnalyticsParameterItemID: column.analyticsString
        ])
    }
    
    class func logSavedContent(_ title: String) {
        Analytics.logEvent("SavedContent", parameters: [
            AnalyticsParameterItemName: title.analyticsString,
            AnalyticsParameterItemID: "SavedContent"
        ])
    }
    
    class func logVisitSponsor(_ name: String) {
        Analytics.logEvent("SponsorVisit", parameters: [
            AnalyticsParameterItemName: name.analyticsString,
            AnalyticsParameterItemID: "SponsorVisit"
        ])
    }
    
    class func logTextSizeChange(_ size: String) {
        Analytics.logEvent("TextSizeChange", parameters: [
            AnalyticsParameterItemName: size.analyticsString,
            AnalyticsParameterItemID: "TextSizeChange"
        ])
    }
    
    class func logDarkModeChange(_ status: String) {
        Analytics.logEvent("DarkModeChange", parameters: [
            AnalyticsParameterItemName: status.analyticsString,
            AnalyticsParameterItemID: "DarkModeChange"
        ])
    }
    
    class func logShare(_ action: String) {
        Analytics.logEvent("SharedContent", parameters: [
            AnalyticsParameterItemName: action.analyticsString,
            AnalyticsParameterItemID: "SharedContent"
        ])
    }
    
    class func logError(_ vc: LoggableViewController, error: RTRSError) {
        Analytics.logEvent(error.alertTitle.analyticsString, parameters: [
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
