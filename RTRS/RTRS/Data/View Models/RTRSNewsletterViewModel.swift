//
//  RTRSNewsletterViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 11/1/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSNewsletterViewModel: NSObject, RTRSViewModel {
    var name: String
    var url: URL
    
    enum CodingKeys: String {
        case name = "name"
        case url = "url"
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
    }
    
    func pageName() -> String {
        return self.name
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Dario")
    }
    
    func pageUrl() -> URL? {
        return self.url
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: CodingKeys.name.rawValue)
        coder.encode(self.url, forKey: CodingKeys.url.rawValue)
    }

    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as! String
        let url = aDecoder.decodeObject(forKey: CodingKeys.url.rawValue) as! URL
        
        self.init(name: name, url: url)
    }
}

class RTRSTshirtStoreViewModel: NSObject, RTRSViewModel {
    var name: String
    var url: URL
    
    enum CodingKeys: String {
        case name = "name"
        case url = "url"
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
    }
    
    func pageName() -> String {
        return self.name
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "TJ")
    }
    
    func pageUrl() -> URL? {
        return self.url
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: CodingKeys.name.rawValue)
        coder.encode(self.url, forKey: CodingKeys.url.rawValue)
    }

    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as! String
        let url = aDecoder.decodeObject(forKey: CodingKeys.url.rawValue) as! URL
        
        self.init(name: name, url: url)
    }
}
