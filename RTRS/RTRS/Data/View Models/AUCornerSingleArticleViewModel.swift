//
//  AUCornerSingleArticleViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

protocol SingleContentViewModel {
    var title: String? { get }
    var contentDescription: String? { get }
    var dateString: String? { get }
    var imageUrl: URL? { get }
}

class AUCornerSingleArticleViewModel: NSObject, RTRSViewModel, SingleContentViewModel {
    
    func pageName() -> String {
        return self.title ?? ""
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    enum CodingKeys: String {
        case title = "title"
        case articleDescription = "articleDescription"
        case baseURL = "baseURL"
        case dateString = "dateString"
        case imageUrl = "imageUrl"
        case htmlString = "htmlString"
    }
    
    let title: String?
    let contentDescription: String?
    let baseURL: URL?
    let dateString: String?
    let imageUrl: URL?
    var htmlString: String?
    
    init(doc: Document?, title: String?, articleDescription: String?, baseURL: URL?, dateString: String?, imageUrl: URL?, htmlString: String?) {
        self.title = title
        self.contentDescription = articleDescription
        self.baseURL = baseURL
        self.dateString = dateString
        self.imageUrl = imageUrl
        self.htmlString = htmlString
        super.init()
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: CodingKeys.title.rawValue)
        aCoder.encode(self.contentDescription, forKey: CodingKeys.articleDescription.rawValue)
        aCoder.encode(self.baseURL, forKey: CodingKeys.baseURL.rawValue)
        aCoder.encode(self.dateString, forKey: CodingKeys.dateString.rawValue)
        aCoder.encode(self.imageUrl, forKey: CodingKeys.imageUrl.rawValue)
        aCoder.encode(self.htmlString, forKey: CodingKeys.htmlString.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        let articleDescription = aDecoder.decodeObject(forKey: CodingKeys.articleDescription.rawValue) as? String
        let baseURL = aDecoder.decodeObject(forKey: CodingKeys.baseURL.rawValue) as? URL
        let dateString = aDecoder.decodeObject(forKey: CodingKeys.dateString.rawValue) as? String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? URL
        let htmlString = aDecoder.decodeObject(forKey: CodingKeys.htmlString.rawValue) as? String
        
        self.init(doc: nil, title: title, articleDescription: articleDescription, baseURL: baseURL, dateString: dateString, imageUrl: imageUrl, htmlString: htmlString)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        do {
            if let divElem = try theDoc.getElementsByClass("main-content-wrapper").first() {
                
                if let titleElem = try divElem.getElementsByClass("title").first() {
                    try titleElem.remove()
                }

                if let dateAuthorElem = try divElem.getElementsByClass("date-author").first() {
                    try dateAuthorElem.remove()
                }

                if let imageElem = try divElem.getElementsByClass("sqs-block-content").first() {
                    try imageElem.remove()
                }
                
                if let tagElem = try divElem.getElementsByClass("tags-cats").first() {
                    try tagElem.remove()
                }
                
                if let paginationElem = try divElem.getElementsByClass("pagination").first() {
                    try paginationElem.remove()
                }
                
                let imgElems = try divElem.select("img")
                for imgElem in imgElems {
                    if let dataSrcAttr = try? imgElem.attr("data-src") {
                        try imgElem.attr("src", dataSrcAttr)
                    }
                }
                
                let imgWrapperElems = try divElem.select("div.image-block-wrapper")
                for imgWrapperElem in imgWrapperElems {
                    if let _ = try? imgWrapperElem.attr("style") {
                        try imgWrapperElem.attr("style", "")
                    }
                }
                
                let intrinsicDivElems = try divElem.select("div.intrinsic")
                for intrinsicDivElem in intrinsicDivElems {
                    if let _ = try? intrinsicDivElem.attr("style") {
                        try intrinsicDivElem.attr("style", "")
                    }
                }
                
                let divString = try divElem.html()
                
                var cssString = ""
                
                if let path = Bundle.main.path(forResource: "RTRS", ofType: "css"), let cssFileContents = try? String(contentsOfFile: path) {
                    cssString = cssFileContents
                }
                
                let htmlString = "<html><head><style>\(cssString)</style></head><body>\(divString)</body></html>"
                self.htmlString = htmlString
            }
        } catch {
            print("Error parsing single article viewmodel")
        }
    }
}
