//
//  RTRSGoodBoyClubViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/5/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSGoodBoyClubViewModel: NSObject, GalleryViewModel {
    let etag: String?
    var entries: [GallerySingleEntry] = [GoodDog]()
    var pageDescription: NSAttributedString?
    var pageDescriptionImageURLs: [URL]?
    var completion: ((RTRSViewModel?) -> ())?
    
    enum CodingKeys: String {
        case pageDescription = "pageDescription"
        case entries = "entries"
        case pageDescriptionImageURLs = "pageDescriptionURLs"
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        self.pageDescriptionImageURLs = [URL]()
        
        do {
            let slideElems = try theDoc.getElementsByClass("slide")
            for slide in slideElems {
                guard let imgElem = try? slide.getElementsByTag("img"),
                let imgURLString = try? imgElem.attr("data-src"),
                    let imgURL = URL(string: imgURLString) else { continue }
                
                var name: String?
                var description: String?
                
                if let metaElem = try? slide.getElementsByClass("slide-meta").first() {
                    if let titleElem = try? metaElem.getElementsByClass("title").first() {
                        name = try titleElem.text()
                    }
                    
                    if let descriptionElem = try? metaElem.getElementsByClass("description").first() {
                        description = descriptionElem.description
                    }
                }
                
                self.entries.append(GoodDog(imageURLs: [imgURL], descriptionHTML: description, name: name))
            }
        } catch let error {
            print("Error parsing Good Dog View Model: \(error.localizedDescription)")
        }
        
        print("FINISHED LOADING Good Dog Club")
        
        if let etag = self.etag {
            let keyName = "\(self.pageName())-\(RTRSUserDefaultsKeys.lastUpdated)"
            UserDefaults.standard.set(etag, forKey: keyName)
        }
        self.completion?(self)
    }
    
    func pageName() -> String {
        return RTRSScreenType.goodDogClub.rawValue
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "ByNature")
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return .goodDogClubLoadedNotificationName
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pageDescription, forKey: CodingKeys.pageDescription.rawValue)
        coder.encode(self.pageDescriptionImageURLs, forKey: CodingKeys.pageDescriptionImageURLs.rawValue)
        coder.encode(self.entries, forKey: CodingKeys.entries.rawValue)
    }
    
    required convenience init?(coder: NSCoder) {
        let pups = coder.decodeObject(forKey: CodingKeys.entries.rawValue) as? [GoodDog]
        let description = coder.decodeObject(forKey: CodingKeys.pageDescription.rawValue) as? NSAttributedString
        let imageURLs = coder.decodeObject(forKey: CodingKeys.pageDescriptionImageURLs.rawValue) as? [URL]
        
        self.init(doc: nil, pups: pups, description: description, imageURLs: imageURLs, completion: nil, etag: nil)
    }
    
    required init(doc: Document?, pups: [GoodDog]?, description: NSAttributedString?, imageURLs: [URL]?, completion: ((RTRSViewModel?) -> ())?, etag: String?) {
        self.entries = pups ?? []
        self.pageDescription = description
        self.pageDescriptionImageURLs = imageURLs
        self.completion = completion
        self.etag = etag
        
        super.init()
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
}

class GoodDog: NSObject, NSCoding, GallerySingleEntry {
    
    var urls = [URL]()
    var entryDescriptionHTML: String?
    var name: String?
    
    private enum CodingKeys: String, CodingKey {
        case pupImageURLs = "goodDogImageUrls"
        case pupDescription = "goodDogDescription"
        case pupName = "goodDogName"
    }
    
    init(imageURLs: [URL]?, descriptionHTML: String?, name: String?) {
        self.urls = imageURLs ?? [URL]()
        self.entryDescriptionHTML = descriptionHTML
        self.name = name
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let pupImageURLs = aDecoder.decodeObject(forKey: CodingKeys.pupImageURLs.rawValue) as? [URL]
        let pupDescription = aDecoder.decodeObject(forKey: CodingKeys.pupDescription.rawValue) as? String
        let pupName = aDecoder.decodeObject(forKey: CodingKeys.pupName.rawValue) as? String
        self.init(imageURLs: pupImageURLs, descriptionHTML: pupDescription, name: pupName)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.urls, forKey: CodingKeys.pupImageURLs.rawValue)
        aCoder.encode(self.entryDescriptionHTML, forKey: CodingKeys.pupDescription.rawValue)
        aCoder.encode(self.name, forKey: CodingKeys.pupName.rawValue)
    }
}

