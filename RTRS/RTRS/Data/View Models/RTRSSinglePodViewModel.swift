//
//  RTRSSinglePodViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/4/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSSinglePodViewModel: NSObject, RTRSViewModel, SingleContentViewModel {

    let title: String?
    let dateString: String?
    let contentDescription: String?
    let imageUrl: URL?
    
    enum CodingKeys: String {
        case title = "title"
        case description = "description"
        case imageUrl = "imageUrl"
        case dateString = "dateString"
    }
    
    required init(title: String?, date: String?, description: String?, imageURL: URL?) {
        self.title = title
        self.dateString = date
        self.contentDescription = description
        self.imageUrl = imageURL
        super.init()
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
            
    }
    
    func pageName() -> String {
        return self.title ?? ""
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: CodingKeys.title.rawValue)
        aCoder.encode(self.contentDescription, forKey: CodingKeys.description.rawValue)
        aCoder.encode(self.dateString, forKey: CodingKeys.dateString.rawValue)
        aCoder.encode(self.imageUrl, forKey: CodingKeys.imageUrl.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        let description = aDecoder.decodeObject(forKey: CodingKeys.description.rawValue) as? String
        let dateString = aDecoder.decodeObject(forKey: CodingKeys.dateString.rawValue) as? String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? URL
        
        self.init(title: title, date: dateString, description: description, imageURL: imageUrl)
    }
    
}
