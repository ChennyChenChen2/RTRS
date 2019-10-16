//
//  AboutViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/7/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSAboutViewModel: NSObject, RTRSViewModel {
    func pageName() -> String {
        return self.name ?? "About"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    
    enum CodingKeys: String {
        case name = "Name"
        case image = "Image"
        case body = "Body"
    }

    var name: String?
    var imageUrl: URL?
    var body: NSAttributedString?
    
    init(doc: Document?, name: String?, imageUrl: URL?, body: NSAttributedString?) {
        super.init()
        self.name = name
        self.imageUrl = imageUrl
        self.body = body
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.image.rawValue) as? URL
        let body = aDecoder.decodeObject(forKey: CodingKeys.body.rawValue) as? NSAttributedString
        
        self.init(doc: nil, name: name, imageUrl: imageUrl, body: body)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.imageUrl, forKey: CodingKeys.image.rawValue)
        aCoder.encode(self.body, forKey: CodingKeys.body.rawValue)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let doc = doc else { return }
        do {
            let bodyText = NSMutableAttributedString(string: "")
            let contentDivElements = try doc.getElementsByClass("sqs-block html-block sqs-block-html")
            
            for element in contentDivElements {
                
                if try element.getElementsByTag("h3").count > 0 {
                    try element.remove()
                    continue
                }
                
                let pElems = try element.getElementsByTag("p")
                for pElem in pElems {
                    if !pElem.description.contains("Squarespace") && !pElem.description.contains("contact us") {
                        let attrString = NSAttributedString.attributedStringFrom(element: pElem)
                        bodyText.append(attrString)
                        bodyText.append(NSAttributedString(string: "\n"))
                    }
                }
            }
            
            self.body = bodyText
            
            if let divElement = try doc.getElementsByClass("image-block-wrapper lightbox  has-aspect-ratio").first(),
                let imgElement = try divElement.getElementsByTag("img").first() {
                let src = try imgElement.attr("src")
                if let imageUrl = URL(string: src) {
                    self.imageUrl = imageUrl
                }
            }
        } catch {
            print("Error parsing about view model")
        }
    }
}
