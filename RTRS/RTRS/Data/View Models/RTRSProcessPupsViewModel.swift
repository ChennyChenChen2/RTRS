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
    var processPups: [ProcessPup]?
    var pageDescription: String?
    var pageDescriptionImageURLs: [URL]?
    
    enum CodingKeys: String {
        case pageDescription = "pageDescription"
        case processPups = "processsPups"
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
                        if pElems.count == 2 {
                            let description1 = try pElems[0].text()
                            let description2 = try pElems[1].text()
                            self.pageDescription = description1 + "\n\n" + description2
                        }
                        
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
                        
                    }
                }
            }
        } catch let error {
            print("Error parsing Process Pups View Model: \(error.localizedDescription)")
        }
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
        coder.encode(self.processPups, forKey: CodingKeys.processPups.rawValue)
        coder.encode(self.pageDescription, forKey: CodingKeys.pageDescription.rawValue)
        coder.encode(self.pageDescriptionImageURLs, forKey: CodingKeys.pageDescriptionImageURLs.rawValue)
    }
    
    required convenience init?(coder: NSCoder) {
        let pups = coder.decodeObject(forKey: CodingKeys.processPups.rawValue) as? [ProcessPup]
        let description = coder.decodeObject(forKey: CodingKeys.pageDescription.rawValue) as? String
        let imageURLs = coder.decodeObject(forKey: CodingKeys.pageDescriptionImageURLs.rawValue) as? [URL]
        
        self.init(doc: nil, pups: pups, description: description, imageURLs: imageURLs)
    }
    
    required init(doc: Document?, pups: [ProcessPup]?, description: String?, imageURLs: [URL]?) {
        self.processPups = pups
        self.pageDescription = description
        self.pageDescriptionImageURLs = imageURLs
        super.init()
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
}

struct ProcessPup: Codable {
    
    var pupImageURL: URL
    var pupDescription: String
    var pupName: String
    
    private enum CodingKeys: String, CodingKey {
        case pupImageURL
        case pupDescription
        case pupName
    }
    
    init(imageURL: URL, description: String, name: String) {
        self.pupImageURL = imageURL
        self.pupDescription = description
        self.pupName = name
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let pupImageURL = try values.decode(URL.self, forKey: .pupImageURL)
        let pupDescription = try values.decode(String.self, forKey: .pupDescription)
        let pupName = try values.decode(String.self, forKey: .pupName)
        self.init(imageURL: pupImageURL, description: pupDescription, name: pupName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.pupImageURL, forKey: .pupImageURL)
        try container.encode(self.pupDescription, forKey: .pupDescription)
        try container.encode(self.pupName, forKey: .pupName)
    }
}
