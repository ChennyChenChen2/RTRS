//
//  RTRSHomeViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

struct HomeItem: Codable {
    var imageUrl: URL?
    var text: String?
    var actionText: String?
    var actionUrl: URL?
    
    init(imageUrl: URL, text: String?, actionText: String?, actionUrl: URL?) {
        self.imageUrl = imageUrl
        self.text = text
        self.actionText = actionText
        self.actionUrl = actionUrl
    }
    
    init(from decoder: Decoder) throws {
        
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
}

struct Announcement: Codable {
    var text: String?
    var actionUrl: URL?
    
    init(from decoder: Decoder) throws {
        
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
}

class RTRSHomeViewModel: RTRSViewModel {
    
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
        self.items = items
        self.name = name
        self.announcement = announcement
        
        if let theDoc = doc {
            self.extractDataFromDoc(doc: theDoc)
        }
    }
    
    func extractDataFromDoc(doc: Document) {
        do {
            var homeItems = [HomeItem]()
            
            let imgElems = try doc.getElementsByClass("thumb-image")
            let titleElems = try doc.getElementsByClass("sqs-block html-block sqs-block-html")
            let actionElems = try doc.getElementsByClass("sqs-block-button-element--large sqs-block-button-element")
            
            for i in 0..<actionElems.count {
                let actionElem = actionElems[i]
                if i < titleElems.count && i < imgElems.count {
                    let titleElem = titleElems[i]
                    let imgElem = imgElems[i]
                    if let imgURL = URL(string: try imgElem.attr("data-src")),
                    let h1Elem = try titleElem.getElementsByTag("h1").first(),
                    let actionText = try? actionElem.text(),
                    let actionURL = URL(string: try actionElem.attr("href")) {
                        let title = NSAttributedString.attributedStringFrom(element: h1Elem)
                        if !title.string.contains("Squarespace") {
                            let homeItem = HomeItem(imageUrl: imgURL, text: title.string, actionText: actionText, actionUrl: actionURL)
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
