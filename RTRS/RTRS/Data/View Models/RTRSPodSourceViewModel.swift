//
//  RTRSPodSourceViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/5/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

struct PodInfo {
    var title: String
    var link: URL
}

class RTRSPodSourceViewModel: NSObject, RTRSViewModel {
    func pageUrl() -> URL? {
        return nil
    }
    
    enum CodingKeys: String {
        case pods = "Pods"
        case podUrls = "Pod Urls"
     }
    
    func pageName() -> String {
        return "Pod Source"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pods, forKey: CodingKeys.pods.rawValue)
        coder.encode(self.podUrls, forKey: CodingKeys.podUrls.rawValue)
    }
    
    var pods = [String: URL]() // TODO: Guess we don't need this anymore
    var podUrls = [URL]()
    var ignoreTitles: [String]
    
    required init(doc: Document?, pods: [String: URL]?, podUrls: [URL]? = nil, ignoreTitles: [String]?) {
        self.pods = pods ?? [String: URL]()
        self.podUrls = podUrls ?? [URL]()
        self.ignoreTitles = ignoreTitles ?? [String]()
        super.init()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder: NSCoder) {
        let pods = coder.decodeObject(forKey: CodingKeys.pods.rawValue) as? [String: URL]
        let podUrls = coder.decodeObject(forKey: CodingKeys.podUrls.rawValue) as? [URL]
        
        self.init(doc: nil, pods: pods, podUrls: podUrls, ignoreTitles: nil)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc else { return }
        
        do {
            let items = try theDoc.getElementsByTag("item")
            for item in items {
                if let titleElem = try item.getElementsByTag("title").first(), let linkElem = try item.getElementsByTag("enclosure").first(), let link = URL(string: try linkElem.attr("url")) {
                    if let title = try? titleElem.text(), !self.ignoreTitles.contains(title) {
                        podUrls.append(link)
                    }
                }
            }
            
            print("Loaded pod URLs")
        } catch {
            print("Error parsing pod source")
        }
    }
}
