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
    let url: URL?
    let imageUrl: URL?
    
    required init(title: String?, date: String?, description: String?, imageURL: URL?) {
        self.title = title
        self.dateString = date
        self.contentDescription = description
        self.url = nil
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
    
    func encode(with coder: NSCoder) {
        
    }
    
    required convenience init?(coder: NSCoder) {
        self.init(title: nil, date: nil, description: nil, imageURL: nil)
    }
    
}
