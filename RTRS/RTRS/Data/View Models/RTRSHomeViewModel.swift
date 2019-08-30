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
            let homeItemElems = try doc.getElementsByClass("col sqs-col-6 span-6")
            for homeItemElem in homeItemElems {
                if let imgElem = try homeItemElem.getElementsByTag("img").first(),
                    let textElem = try homeItemElem.getElementsByClass("sqs-block html-block sqs-block-html").first(),
                    let h1Elem = try textElem.getElementsByTag("h1").first(),
                    let actionElem = try homeItemElem.getElementsByClass("sqs-block-button-container--center").first(),
                    let aElem = try actionElem.getElementsByTag("a").first(),
                    let imgURL = URL(string: try imgElem.attr("src")),
                    let actionURL = URL(string: try aElem.attr("href")) {
                    let text = NSAttributedString.attributedStringFrom(element: h1Elem)
                    let actionText = try aElem.text()
                    
                    let homeItem = HomeItem(imageUrl: imgURL, text: text.string, actionText: actionText, actionUrl: actionURL)
                    homeItems.append(homeItem)
                }
            }
        } catch {
            print("Unable to parse home page HTML")
        }
    }
    
}
