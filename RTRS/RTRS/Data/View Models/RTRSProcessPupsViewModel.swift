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
    var pageDescription: NSAttributedString?
    var pageDescriptionImageURLs: [URL]?
    var completion: ((RTRSViewModel?) -> ())?
    
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
                let rowElems = try pageWrapperElem.getElementsByClass("sqs-block html-block sqs-block-html")
                let buffer = NSMutableAttributedString()
                for i in 0..<rowElems.count {
                    let row = rowElems[i]
                    
                    if i == 0 {
                        // First element, we need description and image URLs
                        let pElems = try row.getElementsByTag("p")

                        let aStrings = pElems.compactMap({ (elem) -> NSAttributedString? in
                            return NSAttributedString.attributedStringFrom(element: elem)
                            })
                        for string in aStrings {
                            buffer.append(string)
                        }
                        
                        if let parent = row.parent() {
                            let imgElems = try parent.getElementsByTag("img")
                            let filteredElems = imgElems.filter { (elem) -> Bool in
                                return elem.hasClass("thumb-image")
                            }
                            for imgElem in filteredElems {
                                if let url = URL(string: try imgElem.attr("data-src")) {
                                    self.pageDescriptionImageURLs?.append(url)
                                }
                            }
                        }
                    } else if  i == 1 {
                        let pElems = try row.getElementsByTag("p")
                        let aStrings = pElems.compactMap({ (elem) -> NSAttributedString? in
                            return NSAttributedString.attributedStringFrom(element: elem)
                            })
                        for string in aStrings {
                            buffer.append(string)
                        }
                        self.pageDescription = buffer
                        continue
                    } else {
                        var imgURLs = [URL]()
                        var name: String?
                        let description = NSMutableAttributedString()
                        
                        let parents = row.parents()
                        var parentDiv: Element?
                        
                        for p in parents {
                            if try p.className() == "row sqs-row" {
                                parentDiv = p
                                break
                            }
                        }
                        
                        if let parent = parentDiv {
                            let imgElems = try parent.getElementsByTag("img")
                            let filteredElems = imgElems.filter { (elem) -> Bool in
                                return elem.hasClass("thumb-image")
                            }
                            for imgElem in filteredElems {
                                if let url = URL(string: try imgElem.attr("data-src")) {
                                    imgURLs.append(url)
                                }
                            }
                        }
                        
                        var nElem: Element?
                        if let e = try row.getElementsByTag("h3").first() {
                            nElem = e
                        } else if let e = try row.getElementsByTag("h2").first() {
                            nElem = e
                        }
                        
                        if let nameElem = nElem {
                            name = try nameElem.text()
                        }
                        
                        let descriptionElems = try row.getElementsByTag("p")
                        for descriptionElem in descriptionElems {
                            let brElems = try descriptionElem.select("br")
                            // Replace <br> with spaces
                            for brElem in brElems {
                                let pHTML = "<p> </p>"
                                let pDoc = try SwiftSoup.parse(pHTML)
                                let pElem = try pDoc.select("p").first()!
                                try brElem.replaceWith(pElem)
                            }
                            
                            description.append(NSAttributedString.attributedStringFrom(element: descriptionElem))
                        }
                        
                        if let theName = name {
                            self.processPups.append(ProcessPup(imageURLs: imgURLs, description: description, name: theName))
                        }
                    }
                }
            }
        } catch let error {
            print("Error parsing Process Pups View Model: \(error.localizedDescription)")
        }
        
        print("FINISHED LOADING PROCESS PUPS")
        self.completion?(self)
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
        let description = coder.decodeObject(forKey: CodingKeys.pageDescription.rawValue) as? NSAttributedString
        let imageURLs = coder.decodeObject(forKey: CodingKeys.pageDescriptionImageURLs.rawValue) as? [URL]
        
        self.init(doc: nil, pups: pups, description: description, imageURLs: imageURLs, completion: nil)
    }
    
    required init(doc: Document?, pups: [ProcessPup]?, description: NSAttributedString?, imageURLs: [URL]?, completion: ((RTRSViewModel?) -> ())?) {
        self.processPups = pups ?? []
        self.pageDescription = description
        self.pageDescriptionImageURLs = imageURLs
        self.completion = completion
        
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
