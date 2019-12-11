//
//  RTRSProcessPupsViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 11/28/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSProcessPupsViewModel: NSObject, RTRSViewModel {
    var processPups: [ProcessPup] = [ProcessPup]()
    var pageDescription: String?
    var pageDescriptionImageURLs: [URL]?
    
    enum CodingKeys: String {
        case pageDescription = "pageDescription"
        case processPups = "processPups"
        case pageDescriptionImageURLs = "pageDescriptionURLs"
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        self.pageDescriptionImageURLs = [URL]()
        
        do {
            if let pageWrapperElem = try theDoc.getElementById("pageWrapper") {
                let rowElems = try pageWrapperElem.getElementsByClass("row sqs-row")
                for i in 0..<rowElems.count {
                    let row = rowElems[i]
                    if i == 0 {
                        // First element, we need description and image URLs
                        let pElems = try row.getElementsByTag("p")

                        self.pageDescription = pElems.compactMap({ (elem) -> String? in
                            return try? elem.text()
                        }).joined()
                        
                        let imgElems = try row.getElementsByTag("img")
                        let filteredElems = imgElems.filter { (elem) -> Bool in
                            return elem.hasClass("thumb-image")
                        }
                        for imgElem in filteredElems {
                            if let url = URL(string: try imgElem.attr("data-src")) {
                                self.pageDescriptionImageURLs?.append(url)
                            }
                        }
                    } else {
                        if row.children().contains(where: { (elem) -> Bool in
                            return elem.hasClass("col sqs-col-12 span-12")
                        }) {
                            continue
                        } else {
                            var imgURLs = [URL]()
                            var name: String?
                            var description: NSAttributedString?
                            
                            let imgElems = try row.getElementsByTag("img")
                            let filteredElems = imgElems.filter { (elem) -> Bool in
                                return elem.hasClass("thumb-image")
                            }
                            for imgElem in filteredElems {
                                if let url = URL(string: try imgElem.attr("data-src")) {
                                    imgURLs.append(url)
                                }
                            }
                            
                            let textElems = try row.getElementsByClass("sqs-block html-block sqs-block-html")
                            if let elem = textElems.first() {
                                if let nameElem = try elem.getElementsByTag("h3").first(),
                                    let descriptionElem = try elem.getElementsByTag("p").first() {
                                    name = try nameElem.text()
                                    description = NSAttributedString.attributedStringFrom(element: descriptionElem)
                                }
                            }
                            
                            if let theName = name, let theDescription = description {
                                self.processPups.append(ProcessPup(imageURLs: imgURLs, description: theDescription, name: theName))
                            }
                        }
                    }
                }
            }
        } catch let error {
            print("Error parsing Process Pups View Model: \(error.localizedDescription)")
        }
        
        print("HERE")
    }
    
    func pageName() -> String {
        return "Process Pups"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Top-Nav-Image")
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pageDescription, forKey: CodingKeys.pageDescription.rawValue)
        coder.encode(self.pageDescriptionImageURLs, forKey: CodingKeys.pageDescriptionImageURLs.rawValue)
        coder.encode(self.processPups, forKey: CodingKeys.processPups.rawValue)
    }
    
    required convenience init?(coder: NSCoder) {
        let pups = coder.decodeObject(forKey: CodingKeys.processPups.rawValue) as? [ProcessPup]
        let description = coder.decodeObject(forKey: CodingKeys.pageDescription.rawValue) as? String
        let imageURLs = coder.decodeObject(forKey: CodingKeys.pageDescriptionImageURLs.rawValue) as? [URL]
        
        self.init(doc: nil, pups: pups, description: description, imageURLs: imageURLs)
    }
    
    required init(doc: Document?, pups: [ProcessPup]?, description: String?, imageURLs: [URL]?) {
        self.processPups = pups ?? []
        self.pageDescription = description
        self.pageDescriptionImageURLs = imageURLs
        super.init()
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
}

class ProcessPup: NSObject, NSCoding {
    
    var pupImageURLs: [URL]? = [URL]()
    var pupDescription: NSAttributedString?
    var pupName: String?
    
    private enum CodingKeys: String, CodingKey {
        case pupImageURLs = "pupImageUrls"
        case pupDescription = "pupDescription"
        case pupName = "pupName"
    }
    
    init(imageURLs: [URL]?, description: NSAttributedString?, name: String?) {
        self.pupImageURLs = imageURLs
        self.pupDescription = description
        self.pupName = name
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let pupImageURLs = aDecoder.decodeObject(forKey: CodingKeys.pupImageURLs.rawValue) as? [URL]
        let pupDescription = aDecoder.decodeObject(forKey: CodingKeys.pupDescription.rawValue) as? NSAttributedString
        let pupName = aDecoder.decodeObject(forKey: CodingKeys.pupName.rawValue) as? String
        self.init(imageURLs: pupImageURLs, description: pupDescription, name: pupName)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.pupImageURLs, forKey: CodingKeys.pupImageURLs.rawValue)
        aCoder.encode(self.pupDescription, forKey: CodingKeys.pupDescription.rawValue)
        aCoder.encode(self.pupName, forKey: CodingKeys.pupName.rawValue)
    }
}
