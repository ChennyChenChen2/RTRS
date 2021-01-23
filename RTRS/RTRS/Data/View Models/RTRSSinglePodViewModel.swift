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
    func loadedNotificationName() -> Notification.Name? {
        return nil
    }
    
    func pageUrl() -> URL? {
        return nil
    }

    let title: String?
    let dateString: String?
    let contentDescription: String?
    let imageUrl: NSURL?
    let sharingUrl: NSURL?
    var youtubeUrl: NSURL?
    
    enum CodingKeys: String {
        case title = "title"
        case description = "description"
        case imageUrl = "imageUrl"
        case dateString = "dateString"
        case sharingUrl = "sharingUrl"
        case youtubeUrl = "youtubeUrl"
    }
    
    required init(doc: Document?, title: String?, date: String?, description: String?, imageURL: NSURL?, sharingUrl: NSURL?, youtubeUrl: NSURL?) {
        self.title = title
        self.dateString = date
        self.contentDescription = description
        self.imageUrl = imageURL
        self.sharingUrl = sharingUrl
        self.youtubeUrl = youtubeUrl
        super.init()
    }

    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
     // Unimplemented-- we lazy load pod data
    }

    func lazyLoadPodData(completion: () -> ()) {
        guard let sharingURL = self.sharingUrl as? URL,
            let htmlString = try? String.init(contentsOf: sharingURL),
            let doc = try? SwiftSoup.parse(htmlString),
            let postElem = try? doc.getElementsByClass("body entry-content").first() else { completion(); return }
        
        if let youtubeElem = try? postElem.getElementsByAttributeValueContaining("src", "www.youtube.com").first(),
        let youtubeUrlString = try? youtubeElem.attr("src"),
        let youtubeUrl = NSURL(string: youtubeUrlString) {
            self.youtubeUrl = youtubeUrl
            completion()
            return
        }
        
        let regex = try! NSRegularExpression(pattern: "www.youtube.com/embed/[A-Za-z0-9]+", options: .caseInsensitive)
        if let youtubeElem = try? postElem.getElementsByAttributeValueContaining("data-block-json", "www.youtube.com").first(),
           let blob = try? youtubeElem.attr("data-block-json"),
           let decodedBlob = blob.removingPercentEncoding
           {
            let range = NSRange(location: 0, length: decodedBlob.utf16.count)
            if let match = regex.firstMatch(in: decodedBlob, options: [], range: range),
               let range = Range(match.range, in: decodedBlob) {
                let youtubeUrlString = String(decodedBlob[range])
                self.youtubeUrl = NSURL(string: "https://\(youtubeUrlString)")
                completion()
                return
            }
            
        }
        
        completion()
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
        aCoder.encode(self.sharingUrl, forKey: CodingKeys.sharingUrl.rawValue)
        aCoder.encode(self.youtubeUrl, forKey: CodingKeys.youtubeUrl.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        let description = aDecoder.decodeObject(forKey: CodingKeys.description.rawValue) as? String
        let dateString = aDecoder.decodeObject(forKey: CodingKeys.dateString.rawValue) as? String
        let imageUrl = aDecoder.decodeObject(forKey: CodingKeys.imageUrl.rawValue) as? NSURL
        let sharingUrl = aDecoder.decodeObject(forKey: CodingKeys.sharingUrl.rawValue) as? NSURL
        let youtubeUrl = aDecoder.decodeObject(forKey: CodingKeys.youtubeUrl.rawValue) as? NSURL
        
        self.init(doc: nil, title: title, date: dateString, description: description, imageURL: imageUrl, sharingUrl: sharingUrl, youtubeUrl: youtubeUrl)
    }
}
