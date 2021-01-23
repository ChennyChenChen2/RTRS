//
//  RTRSAbbieArtGallery.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/19/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import Foundation

import UIKit
import SwiftSoup

protocol GalleryViewModel: RTRSViewModel {
    var entries: [GallerySingleEntry] { get set }
    var pageDescription: NSAttributedString? { get set }
    var pageDescriptionImageURLs: [URL]? { get set }
}

protocol GallerySingleEntry: NSObject {
    var urls: [URL] { get set }
    var name: String? { get set }
    var entryDescriptionHTML: String? { get set }
}

class RTRSAbbieArtGalleryViewModel: NSObject, GalleryViewModel {
    let etag: String?
    var entries: [GallerySingleEntry] = [AbbieSingleEntry]()
    var pageDescriptionImageURLs: [URL]?
    var completion: ((RTRSViewModel?) -> ())?
    
    var pageDescription: NSAttributedString?
    
    enum CodingKeys: String {
        case pageDescription = "pageDescription"
        case entries = "entries"
        case pageDescriptionImageURLs = "pageDescriptionURLs"
    }
    
    private func setDescriptionText() {
        let string = """
            <p>Abbie Huertas <a href="https://twitter.com/digrupert">(@digrupert)</a> does the art for the Rights to Ricky Sanchez Podcast. See some of her previous works here!</p>
        """
        
        guard let doc = try? SwiftSoup.parse(string) else { return }
        let attrString = NSMutableAttributedString(attributedString: NSAttributedString.attributedStringFrom(element: doc))
        let range = NSRange(location: 0, length: attrString.length)
        attrString.addAttribute(.foregroundColor, value: UIColor.white, range: range)
        attrString.addAttribute(.font, value: Utils.defaultFont, range: range)
                
        self.pageDescription = attrString
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        
        do {
            let slides = try theDoc.getElementsByClass("slide")
            for slide in slides {
                if let imgElem = try slide.getElementsByTag("img").first(),
                    let url = URL(string: try imgElem.attr("data-src")) {
                    let galleryEntry = AbbieSingleEntry(imageURLs: [url], description: nil, name: nil)
                    self.entries.append(galleryEntry)
                }
            }
        } catch let error {
            print("Error in Abbie view model: \(error.localizedDescription)")
        }
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return .abbieLoadedNotificationName
    }
    
    func pageName() -> String {
        return RTRSScreenType.abbie.rawValue
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Joel")
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pageDescription, forKey: CodingKeys.pageDescription.rawValue)
        coder.encode(self.pageDescriptionImageURLs, forKey: CodingKeys.pageDescriptionImageURLs.rawValue)
        coder.encode(self.entries, forKey: CodingKeys.entries.rawValue)
    }
    
    required convenience init?(coder: NSCoder) {
        let entries = coder.decodeObject(forKey: CodingKeys.entries.rawValue) as? [AbbieSingleEntry]
        let description = coder.decodeObject(forKey: CodingKeys.pageDescription.rawValue) as? NSAttributedString
        let imageURLs = coder.decodeObject(forKey: CodingKeys.pageDescriptionImageURLs.rawValue) as? [URL]
        
        self.init(doc: nil, entries: entries, description: description, imageURLs: imageURLs, completion: nil, etag: nil)
    }
    
    required init(doc: Document?, entries: [AbbieSingleEntry]?, description: NSAttributedString?, imageURLs: [URL]?, completion: ((RTRSViewModel?) -> ())?, etag: String?) {
        self.entries = entries ?? []
        self.pageDescription = description
        self.pageDescriptionImageURLs = imageURLs
        self.completion = completion
        self.etag = etag
        
        super.init()
        
        self.setDescriptionText()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
}

class AbbieSingleEntry: NSObject, NSCoding, GallerySingleEntry {
    var urls = [URL]()
    var entryDescriptionHTML: String?
    var name: String?
    
    private enum CodingKeys: String, CodingKey {
        case imageUrls = "imageUrls"
        case description = "description"
        case name = "name"
    }
    
    init(imageURLs: [URL]?, description: String?, name: String?) {
        self.urls = imageURLs ?? [URL]()
        self.entryDescriptionHTML = description
        self.name = name
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let pupImageURLs = aDecoder.decodeObject(forKey: CodingKeys.imageUrls.rawValue) as? [URL]
        let pupDescription = aDecoder.decodeObject(forKey: CodingKeys.description.rawValue) as? String
        let pupName = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        self.init(imageURLs: pupImageURLs, description: pupDescription, name: pupName)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.urls, forKey: CodingKeys.imageUrls.rawValue)
        aCoder.encode(self.entryDescriptionHTML, forKey: CodingKeys.description.rawValue)
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
    }
}
