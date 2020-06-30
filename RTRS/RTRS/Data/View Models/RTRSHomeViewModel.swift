//
//  RTRSHomeViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class HomeItem: NSObject, NSCoding {
    
    var imageUrl: NSURL?
    var text: String?
    var actionUrl: NSURL?
    var shouldOpenExternalBrowser: Bool
    
    enum CodingKeys: String {
        case imageUrl = "imageUrl"
        case text = "text"
        case actionText = "actionText"
        case actionUrl = "actionUrl"
        case shouldOpenExternalBrowser = "shouldOpenExternalBrowser"
    }
    
    required init(imageUrl: NSURL?, text: String?, actionUrl: NSURL?, shouldOpenExternalBrowser: Bool) {
        self.imageUrl = imageUrl
        self.text = text
        self.actionUrl = actionUrl
        self.shouldOpenExternalBrowser = shouldOpenExternalBrowser
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.imageUrl, forKey: CodingKeys.imageUrl.rawValue)
        aCoder.encode(self.text, forKey: CodingKeys.text.rawValue)
        aCoder.encode(self.actionUrl, forKey: CodingKeys.actionUrl.rawValue)
        aCoder.encode(self.shouldOpenExternalBrowser, forKey: CodingKeys.shouldOpenExternalBrowser.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? NSURL
        let text = aDecoder.decodeObject(forKey: CodingKeys.text.rawValue) as? String
        let actionUrl = aDecoder.decodeObject(forKey: CodingKeys.actionUrl.rawValue) as? NSURL
        let shouldOpenExternalBrowser = aDecoder.decodeObject(forKey: CodingKeys.shouldOpenExternalBrowser.rawValue) as? Bool
        
        self.init(imageUrl: imageUrl ?? nil, text: text, actionUrl: actionUrl ?? nil, shouldOpenExternalBrowser: shouldOpenExternalBrowser ?? false)
    }
}

class Announcement: NSObject, NSCoding {
    var text: String?
    var actionUrl: URL?
    
    enum CodingKeys: String {
        case text = "text"
        case actionUrl = "actionUrl"
    }
    
    required init(text: String?, actionUrl: URL?) {
        self.text = text
        self.actionUrl = actionUrl
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.text, forKey: CodingKeys.text.rawValue)
        aCoder.encode(self.actionUrl, forKey: CodingKeys.actionUrl.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let text = aDecoder.decodeObject(forKey: CodingKeys.text.rawValue) as? String
        let actionUrl = aDecoder.decodeObject(forKey: CodingKeys.actionUrl.rawValue) as? URL
        
        self.init(text: text, actionUrl: actionUrl)
    }
}

class RTRSHomeViewModel: NSObject, RTRSViewModel {
    func loadedNotificationName() -> Notification.Name? {
        return .homeLoadedNotificationName
    }
    
    enum CodingKeys: String {
        case items = "Items"
        case name = "Name"
        case announcement = "Announcement"
        case ignoreTitles = "IgnoreTitles"
    }
    
    var items: [HomeItem]? = [HomeItem]()
    var name: String?
    var announcement: Announcement?
    var ignoreTitles: [String] = []
    
    func pageName() -> String {
        return "Home"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.items, forKey: CodingKeys.items.rawValue)
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.announcement, forKey: CodingKeys.announcement.rawValue)
        aCoder.encode(self.ignoreTitles, forKey: CodingKeys.ignoreTitles.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let items = aDecoder.decodeObject(forKey: CodingKeys.items.rawValue) as? [HomeItem]
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let announcement = aDecoder.decodeObject(forKey: CodingKeys.announcement.rawValue) as? Announcement
        let ignoreTitles = aDecoder.decodeObject(forKey: CodingKeys.ignoreTitles.rawValue) as? [String]
        
        self.init(doc: nil, items: items, name: name, announcement: announcement, ignoreTitles: ignoreTitles ?? [])
    }
    
    required init(doc: Document?, items: [HomeItem]?, name: String?, announcement: Announcement?, ignoreTitles: [String]) {
        super.init()
        self.items = items
        self.name = name
        self.announcement = announcement
        self.ignoreTitles = ignoreTitles
        
        if let theDoc = doc {
            self.extractDataFromDoc(doc: theDoc, urls: nil)
        }
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let doc = doc else { return }
        do {
            var homeItems = [HomeItem]()
            
//            let imgElems = try doc.getElementsByClass("thumb-image")
            let imgElems = try doc.getElementsByClass("sqs-block image-block sqs-block-image")
//            let titleElems = try doc.getElementsByClass("sqs-block html-block sqs-block-html").filter({ (elem) -> Bool in
//                do {
//                    let hasH1 = try elem.getElementsByTag("h1").count > 0
//                    let hasH2 = try elem.getElementsByTag("h2").count > 0
//                    return hasH1 || hasH2
//                } catch {
//                    return false
//                }
//            })
//            let actionElems = try doc.getElementsByClass("sqs-block-button-element--large sqs-block-button-element")
            
            for i in 0..<imgElems.count {
                let imgElemParent = imgElems[i]
                let imgElemChild = try imgElemParent.getElementsByClass("thumb-image").first
                
//                let actionSiblings = imgElemParent.siblingElements().filter { (elem) -> Bool in
//                    do {
//                        return try elem.getElementsByClass("sqs-block-button-element--large sqs-block-button-element").count > 0 && !elem.hasClass("row sqs-row")
//                    } catch {
//                        return false
//                    }
//                }
                
                let titleSiblings = imgElemParent.siblingElements().filter { (elem) -> Bool in
                    return elem.hasClass("sqs-block html-block sqs-block-html")
                }
                
                if let imgElem = imgElemChild {
                    let titleElem = titleSiblings.first
//                    let actionParent = actionSiblings.first
                    let actionElem = try? titleElem?.getElementsByTag("a").first()
                    
                    if let imgURL = URL(string: try imgElem.attr("data-src")) {
                        if let theActionElem = actionElem, let urlString = try? theActionElem.attr("href"), let url = URL(string: urlString) {
                            var titleElemPlaceholder: Element? = nil
                            if let h2Elem = try titleElem?.getElementsByTag("h2").first() {
                                titleElemPlaceholder = h2Elem
                            } else if let h1Elem = try titleElem?.getElementsByTag("h1").first() {
                                titleElemPlaceholder = h1Elem
                            }

                            let title = try titleElemPlaceholder?.text()
                            let nsImgURL = imgURL as NSURL
                            let nsActionURL = url as NSURL
                            if (title != nil && !title!.string.contains("Squarespace")) || title == nil {
                                let shouldOpenExternalBrowser = title != nil ? self.ignoreTitles.contains(title!) : false
                                let homeItem = HomeItem(imageUrl: nsImgURL, text: title, actionUrl: nsActionURL, shouldOpenExternalBrowser: shouldOpenExternalBrowser)
                                homeItems.append(homeItem)
                            }
                        }
                    }
                }
            }
            self.items = homeItems
        } catch {
            print("Unable to parse home page HTML")
        }
    }
    
}
