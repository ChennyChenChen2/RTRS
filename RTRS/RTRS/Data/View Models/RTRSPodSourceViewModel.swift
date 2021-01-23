//
//  RTRSPodSourceViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/5/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class PodInfo: NSObject, NSCoding {
    var title: String?
    var date: Date?
    var link: NSURL?
    
    enum CodingKeys: String {
        case title = "title"
        case date = "date"
        case link = "link"
    }
    
    required init(title: String?, date: Date?, link: NSURL?) {
        self.title = title
        self.date = date
        self.link = link
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: CodingKeys.title.rawValue)
        aCoder.encode(self.date, forKey: CodingKeys.date.rawValue)
        aCoder.encode(self.link, forKey: CodingKeys.link.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        let date = aDecoder.decodeObject(forKey: CodingKeys.date.rawValue) as? Date
        let link = aDecoder.decodeObject(forKey: CodingKeys.link.rawValue) as? NSURL
        
        self.init(title: title, date: date, link: link)
    }
}

class RTRSPodSourceViewModel: NSObject, RTRSViewModel {
    
    func pageUrl() -> URL? {
        return nil
    }
    
    enum CodingKeys: String {
        case pods = "Pods"
        case podUrls = "Pod Urls"
     }
    
    func pageName() -> String {
        return "Pod Source"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return nil
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.podInfo, forKey: CodingKeys.podUrls.rawValue)
    }
    
    var podInfo = [PodInfo]()
    var ignoreTitles: [String]
    
    required init(doc: Document?, pods: [String: URL]?, podInfo: [PodInfo]? = nil, ignoreTitles: [String]?) {
        self.podInfo = podInfo ?? [PodInfo]()
        self.ignoreTitles = ignoreTitles ?? [String]()
        super.init()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder: NSCoder) {
        let pods = coder.decodeObject(forKey: CodingKeys.pods.rawValue) as? [String: URL]
        let podInfo = coder.decodeObject(forKey: CodingKeys.podUrls.rawValue) as? [PodInfo]
        
        self.init(doc: nil, pods: pods, podInfo: podInfo, ignoreTitles: nil)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        
        do {
            let items = try theDoc.getElementsByTag("item")
            for item in items {
                if let titleElem = try item.getElementsByTag("title").first(), let dateElem = try item.getElementsByTag("pubDate").first(), let linkElem = try item.getElementsByTag("enclosure").first(), let link = NSURL(string: try linkElem.attr("url")) {
                    if let title = try? titleElem.text(), !self.ignoreTitles.contains(title), let dateString = try? dateElem.text() {
                        #if DEBUG
                        if title == "Shake At The Point, and Larry Hughes On Iverson, LeBron, The Bubble and The Nelly Video" {
                            continue
                        }
                        #endif
                        
                        let formatter = DateFormatter()
                        ///Thu, 21 Jan 2021 11:00:00 +0000
                        formatter.dateFormat  = "E, d MMM yyyy HH:mm:ss Z"
                        guard let date = formatter.date(from: dateString) else { continue }
                        
                        let info = PodInfo(title: title, date: date, link: link)
                        podInfo.append(info)
                    }
                }
            }
            
            self.resortPodInfo()
            print("Loaded pod URLs")
        } catch {
            print("Error parsing pod source")
        }
    }
    
    func resortPodInfo() {
        self.podInfo.sort { (p1, p2) -> Bool in
            guard let date1 = p1.date, let date2 = p2.date else { return false }
            return date1.compare(date2) == .orderedDescending
        }
    }
}
