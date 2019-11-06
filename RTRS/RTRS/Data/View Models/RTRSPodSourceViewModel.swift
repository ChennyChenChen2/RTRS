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
    
    required init(doc: Document?, pods: [String: URL]?, podUrls: [URL]? = nil) {
        self.pods = pods ?? [String: URL]()
        self.podUrls = podUrls ?? [URL]()
        super.init()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required convenience init?(coder: NSCoder) {
        let pods = coder.decodeObject(forKey: CodingKeys.pods.rawValue) as? [String: URL]
        let podUrls = coder.decodeObject(forKey: CodingKeys.podUrls.rawValue) as? [URL]
        
        self.init(doc: nil, pods: pods, podUrls: podUrls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theDoc = doc, let element = try? theDoc.getElementsByTag("pubDate").first() else { return }
        
        do {
            let items = try theDoc.getElementsByTag("item")
            for item in items {
                if let titleElem = try item.getElementsByTag("title").first(), let linkElem = try item.getElementsByTag("enclosure").first(), let dateElem = try item.getElementsByTag("pubDate").first(), let dateString = try? dateElem.text(), let link = URL(string: try linkElem.attr("url")) {
                    let inputFormatter = DateFormatter()
                    inputFormatter.dateFormat = "E, dd MMM yyyyy HH:mm:ss Z" // Fri, 28 Dec 2018 18:51:20 +0000
                    
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "MMMM dd, yyyy"
                    if let date = inputFormatter.date(from: dateString) {
                        let formattedString = outputFormatter.string(from: date)
                        pods[formattedString] = link
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
