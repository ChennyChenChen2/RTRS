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
    func pageName() -> String {
        return "Pod Source"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    func encode(with coder: NSCoder) {
        
    }
    
    var pods = [String: URL]()
    
    required init(doc: Document?, name: String) {
        super.init()
        self.extractDataFromDoc(doc: doc, urls: nil)
    }
    
    required init?(coder: NSCoder) {
        
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        print("HERE!")
        guard let theDoc = doc, let element = try? theDoc.getElementsByTag("pubDate").first() else { return }
        
        do {
            let items = try theDoc.getElementsByTag("item")
            for item in items {
                if let titleElem = try item.getElementsByTag("title").first(), let linkElem = try item.getElementsByTag("enclosure").first(), let link = URL(string: try linkElem.attr("url")) {
                    let title = try titleElem.text()
                    pods[title] = link
                }
            }
            
            print("Loaded pod URLs")
        } catch {
            print("Error parsing pod source")
        }
    }
}
