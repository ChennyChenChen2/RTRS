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
    var image: UIImage?
    var body: NSAttributedString?
    
    init(doc: Document?, name: String?, image: UIImage?, body: NSAttributedString?) {
        super.init()
        self.name = name
        self.image = image
        self.body = body
        
        if let theDoc = doc {
            self.extractDataFromDoc(doc: theDoc)
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let image = aDecoder.decodeObject(forKey: CodingKeys.image.rawValue) as? UIImage
        let body = aDecoder.decodeObject(forKey: CodingKeys.body.rawValue) as? NSAttributedString
        
        self.init(doc: nil, name: name, image: image, body: body)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.image, forKey: CodingKeys.image.rawValue)
        aCoder.encode(self.body, forKey: CodingKeys.body.rawValue)
    }
    
    func extractDataFromDoc(doc: Document) {
        do {
            let bodyText = NSMutableAttributedString(string: "")
            let contentDivElements = try doc.getElementsByClass("sqs-block html-block sqs-block-html")
            for element in contentDivElements {
                let pElems = try element.getElementsByTag("p")
                for pElem in pElems {
                    if !pElem.description.contains("Squarespace") {
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
                    URLSession.shared.dataTask(with: imageUrl) { [weak self] (data, response, error) in
                        guard let weakSelf = self else { return }
                        if let theData = data {
                            weakSelf.image = UIImage(data: theData)
                        }
                    }.resume()
                }
            }
        } catch {
            print("Error parsing about view model")
        }
    }
}
