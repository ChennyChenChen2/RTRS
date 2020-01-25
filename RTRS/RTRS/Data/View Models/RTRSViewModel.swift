//
//  RTRSViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import SwiftSoup

protocol RTRSViewModel: NSObject, NSCoding {
    func extractDataFromDoc(doc: Document?, urls: [URL]?)
    func loadedNotificationName() -> Notification.Name?
    func pageName() -> String
    func pageImage() -> UIImage
    func pageUrl() -> URL?
}

extension Notification.Name {
    static let podLoadedNotificationName = Notification.Name("podLoaded")
    static let auLoadedNotificationName = Notification.Name("auLoaded")
    static let normalColumnLoadedNotificationName = Notification.Name("normalColumn")
    static let homeLoadedNotificationName = Notification.Name("homeLoaded")
    static let aboutLoadedNotificationName = Notification.Name("aboutLoaded")
    static let moreLoadedNotificationName = Notification.Name("moreLoaded")
    static let processPupsLoadedNotificationName = Notification.Name("processPupsLoaded")
}
