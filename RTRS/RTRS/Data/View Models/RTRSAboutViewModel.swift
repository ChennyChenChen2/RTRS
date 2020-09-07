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
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return self.name ?? "About"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Brett")
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return .aboutLoadedNotificationName
    }
    
    enum CodingKeys: String {
        case name = "Name"
        case image = "Image"
        case bodyHTML = "BodyHTML"
    }

    var name: String?
    var imageUrl: URL?
    var bodyHTML: String?
    
    init(doc: Document?, name: String?, imageUrl: URL?, bodyHTML: String?) {
        super.init()
        self.name = name
        self.imageUrl = imageUrl
        self.bodyHTML = bodyHTML
        
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.image.rawValue) as? URL
        let bodyHTML = aDecoder.decodeObject(forKey: CodingKeys.bodyHTML.rawValue) as? String
        
        self.init(doc: nil, name: name, imageUrl: imageUrl, bodyHTML: bodyHTML)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.imageUrl, forKey: CodingKeys.image.rawValue)
        aCoder.encode(self.bodyHTML, forKey: CodingKeys.bodyHTML.rawValue)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let doc = doc else { return }
        do {
            var bodyText = ""
            let contentDivElements = try doc.getElementsByClass("sqs-block html-block sqs-block-html")
            
            for element in contentDivElements {
                if try element.getElementsByTag("h3").count > 0 {
                    try element.remove()
                    continue
                }
                
                let pElems = try element.getElementsByTag("p")
                for pElem in pElems {
                    if !pElem.description.contains("Squarespace") && !pElem.description.contains("contact us") {
                        bodyText.append(try pElem.html())
                        bodyText.append("</br></br>")
                    }
                }
            }
            
            let jonHTML = """
                <p>Jon Chen is the developer of this app. He works as an app developer and musician in New York City. You can follow him on Twitter <strong><a target="_blank" href="http://www.twitter.com/ChennyChen_Chen">@ChennyChen_Chen</a>.</strong></p>
            """
            
            self.bodyHTML = bodyText + jonHTML
            
            if let divElement = try doc.getElementsByClass("image-block-wrapper").first(),
                let imgElement = try divElement.getElementsByTag("img").first() {
                let src = try imgElement.attr("src")
                if let imageUrl = URL(string: src) {
                    self.imageUrl = imageUrl
                }
            }
        } catch let error {
            print("Error parsing about view model: \(error)")
        }
    }
}
