//
//  MoreViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSMoreViewModel: NSObject, RTRSViewModel {
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return "More"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "More-Icon")
    }
    
    
    enum CodingKeys: String {
        case pages = "Pages"
    }
    
    var pages: [RTRSViewModel]? = [RTRSViewModel]()
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.pages, forKey: CodingKeys.pages.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let pages = aDecoder.decodeObject(forKey: CodingKeys.pages.rawValue) as? [RTRSViewModel]
        self.init(pages: pages)
    }
    
    required init(pages: [RTRSViewModel]?) {
        self.pages = pages
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        print("MoreViewModel doesn't need HTML extraction")
    }
}
