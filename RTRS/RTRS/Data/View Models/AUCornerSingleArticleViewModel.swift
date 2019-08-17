//
//  AUCornerSingleArticleViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class AUCornerSingleArticleViewModel: RTRSViewModel {
    func pageName() -> String {
        return self.title
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    enum CodingKeys: String {
        case title = "title"
        case description = "description"
        case urlSuffix = "urlSuffix"
        case dateString = "dateString"
        case imageUrl = "imageUrl"
    }
    
    let title: String
    let description: String
    let urlSuffix: String
    let dateString: String
    let imageUrl: URL?
    
    init(title: String, description: String, urlSuffix: String, dateString: String, imageUrl: URL?) {
        self.title = title
        self.description = description
        self.urlSuffix = urlSuffix
        self.dateString = dateString
        self.imageUrl = imageUrl
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: CodingKeys.title.rawValue)
        aCoder.encode(self.description, forKey: CodingKeys.description.rawValue)
        aCoder.encode(self.urlSuffix, forKey: CodingKeys.urlSuffix.rawValue)
        aCoder.encode(self.dateString, forKey: CodingKeys.dateString.rawValue)
        aCoder.encode(self.imageUrl, forKey: CodingKeys.imageUrl.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as! String
        let description = aDecoder.decodeObject(forKey: CodingKeys.description.rawValue) as! String
        let urlSuffix = aDecoder.decodeObject(forKey: CodingKeys.urlSuffix.rawValue) as! String
        let dateString = aDecoder.decodeObject(forKey: CodingKeys.dateString.rawValue) as! String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? URL
        self.init(title: title, description: description, urlSuffix: urlSuffix, dateString: dateString, imageUrl: imageUrl)
    }
    
    func extractDataFromDoc(doc: Document) {
        
    }
}
