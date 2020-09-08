//
//  RTRSSponsorsViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/7/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSSponsorsViewModel: NSObject, RTRSViewModel {
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return "Sponsors"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Wroten")
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return .sponsorsLoadedNotificationName
    }
    
    enum CodingKeys: String {
        case sponsors = "Sponsors"
        case sponsorDescription = "SponsorDescription"
    }

    var sponsors: [Sponsor]
    var sponsorDescription: String?
    
    init(doc: Document?, sponsorDescription: String?, sponsors: [Sponsor]?) {
        self.sponsorDescription = sponsorDescription
        self.sponsors = sponsors ?? []
        super.init()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let sponsors = aDecoder.decodeObject(forKey: CodingKeys.sponsors.rawValue) as? [Sponsor]
        let description = aDecoder.decodeObject(forKey: CodingKeys.sponsorDescription.rawValue) as? String
        
        self.init(doc: nil, sponsorDescription: description, sponsors: sponsors)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.sponsors, forKey: CodingKeys.sponsors.rawValue)
        aCoder.encode(self.sponsorDescription, forKey: CodingKeys.sponsorDescription.rawValue)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let doc = doc else { return }
        do {
            guard let sectionElem = try? doc.getElementById("page") else { return }
            let sponsorElems = try sectionElem.getElementsByTag("p")
            for i in 0..<sponsorElems.count {
                let elem = sponsorElems[i]
                if i < sponsorElems.count - 1 {
                    // Sponsors
                    guard let aElem = try elem.getElementsByTag("a").first() else { continue }
                    
                    let name = try aElem.text()
                    let linkString = try aElem.attr("href")
                    if let link = URL(string: linkString) {
                        try aElem.remove()
                        var promoText = try elem.text()
                        promoText = promoText.replacingOccurrences(of: "- ", with: "")
                        self.sponsors.append(Sponsor(name: name, link: link, promo: promoText))
                    } else {
                        continue
                    }
                } else {
                    // Description
                    self.sponsorDescription = try elem.text()
                }
                
            }
        } catch let error {
            print("Error parsing sponsors view model: \(error)")
        }
    }
}

class Sponsor: NSObject, NSCoding {
    var name: String?
    var link: URL?
    var promo: String?
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case link = "link"
        case promo = "promo"
    }
    
    init(name: String?, link: URL?, promo: String?) {
        self.name = name
        self.link = link
        self.promo = promo
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let link = aDecoder.decodeObject(forKey: CodingKeys.link.rawValue) as? URL
        let promo = aDecoder.decodeObject(forKey: CodingKeys.promo.rawValue) as? String
        self.init(name: name, link: link, promo: promo)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.link, forKey: CodingKeys.link.rawValue)
        aCoder.encode(self.promo, forKey: CodingKeys.promo.rawValue)
    }
}
