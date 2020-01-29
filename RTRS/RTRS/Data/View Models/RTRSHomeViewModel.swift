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
    
    var imageUrl: URL?
    var text: String?
    var actionText: String?
    var actionUrl: URL?
    
    enum CodingKeys: String {
        case imageUrl = "imageUrl"
        case text = "text"
        case actionText = "actionText"
        case actionUrl = "actionUrl"
    }
    
    required init(imageUrl: URL?, text: String?, actionText: String?, actionUrl: URL?) {
        self.imageUrl = imageUrl
        self.text = text
        self.actionText = actionText
        self.actionUrl = actionUrl
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.imageUrl, forKey: CodingKeys.imageUrl.rawValue)
        aCoder.encode(self.text, forKey: CodingKeys.text.rawValue)
        aCoder.encode(self.actionText, forKey: CodingKeys.actionText.rawValue)
        aCoder.encode(self.actionUrl, forKey: CodingKeys.actionUrl.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? URL
        let text = aDecoder.decodeObject(forKey: CodingKeys.text.rawValue) as? String
        let actionText = aDecoder.decodeObject(forKey: CodingKeys.actionText.rawValue) as? String
        let actionUrl = aDecoder.decodeObject(forKey: CodingKeys.actionUrl.rawValue) as? URL
        
        self.init(imageUrl: imageUrl, text: text, actionText: actionText, actionUrl: actionUrl)
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
    }
    
    var items: [HomeItem]? = [HomeItem]()
    var name: String?
    var announcement: Announcement?
    
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
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let items = aDecoder.decodeObject(forKey: CodingKeys.items.rawValue) as? [HomeItem]
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let announcement = aDecoder.decodeObject(forKey: CodingKeys.announcement.rawValue) as? Announcement
        
        self.init(doc: nil, items: items, name: name, announcement: announcement)
    }
    
    required init(doc: Document?, items: [HomeItem]?, name: String?, announcement: Announcement?) {
        super.init()
        self.items = items
        self.name = name
        self.announcement = announcement
        
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
                
                let actionSiblings = imgElemParent.siblingElements().filter { (elem) -> Bool in
                    do {
                        return try elem.getElementsByClass("sqs-block-button-element--large sqs-block-button-element").count > 0 && !elem.hasClass("row sqs-row")
                    } catch {
                        return false
                    }
                }
                
                let titleSiblings = imgElemParent.siblingElements().filter { (elem) -> Bool in
                    return elem.hasClass("sqs-block html-block sqs-block-html")
                }
                
                if let imgElem = imgElemChild {
                    let titleElem = titleSiblings.first
                    let actionParent = actionSiblings.first
                    let actionElem = try? actionParent?.getElementsByClass("sqs-block-button-element--large sqs-block-button-element").first
                    
                    if let imgURL = URL(string: try imgElem.attr("data-src")) {
                        let actionText = try? actionElem?.text()
                        var actionURL: URL?
                        if let actionElem = actionElem, let urlString = try? actionElem.attr("href"), let url = URL(string: urlString) {
                            actionURL = url
                        }
                    
                        var titleElemPlaceholder: Element? = nil
                        if let h2Elem = try titleElem?.getElementsByTag("h2").first() {
                            titleElemPlaceholder = h2Elem
                        } else if let h1Elem = try titleElem?.getElementsByTag("h1").first() {
                            titleElemPlaceholder = h1Elem
                        }

                        let title = try titleElemPlaceholder?.text()
                        if (title != nil && !title!.string.contains("Squarespace")) || title == nil {
                            let homeItem = HomeItem(imageUrl: imgURL, text: title, actionText: actionText, actionUrl: actionURL)
                            homeItems.append(homeItem)
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
