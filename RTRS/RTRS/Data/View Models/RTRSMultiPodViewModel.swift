//
//  RTRSMultiPodViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/4/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSMultiPodViewModel: NSObject, RTRSViewModel, MultiContentViewModel {
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return self.name ?? "The Pod"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Top-Nav-Image")
    }
    
    enum CodingKeys: String {
        case name = "Name"
        case pods = "Pods"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.content, forKey: CodingKeys.pods.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let pods = aDecoder.decodeObject(forKey: CodingKeys.pods.rawValue) as? [RTRSSinglePodViewModel]
        
        self.init(urls: nil, name: name, pods: pods, completionHandler: nil)
    }

    let name: String?
    var content: [SingleContentViewModel] = [RTRSSinglePodViewModel]()
    var completion: ((RTRSViewModel?) -> ())?

    required init(urls: [URL]?, name: String?, pods: [RTRSSinglePodViewModel]?, completionHandler: ((RTRSViewModel?) -> ())?) {
        self.name = name
        self.content = pods ?? []
        self.completion = completionHandler
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls else { return }
        
        for url in theURLs {
            do {
                let htmlString = try String.init(contentsOf: url)
                let doc = try SwiftSoup.parse(htmlString)
                let postElements = try doc.getElementsByTag("article")
                for i in 0..<postElements.count {
                    let postElement = postElements[i]
                    let imageElement = try postElement.getElementsByClass("squarespace-social-buttons inline-style")
                    if let titleElement = try? postElement.getElementsByClass("title").first(),
                        let aElement = try? titleElement.getElementsByTag("a").first(),
                        let dateElement = try? postElement.getElementsByClass("date-author").first(),
                        let title = try? aElement.text(),
                        let urlSuffix = try? aElement.attr("href"),
                        let descriptionTextElement = try? postElement.getElementsByTag("p").first(),
                        let podDescription = try? descriptionTextElement.text(),
                        let imageAttribute = try? imageElement.attr("data-asset-url")
                    {
                        guard let encodedUrlSuffix = urlSuffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                        let articleUrl = URL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else { continue }
                        
                        if let dateAElem = try? dateElement.getElementsByTag("a").first() {
                            try dateAElem.remove()
                        }
                        
                        var theTitle = title
                        if let openBracketIndex = title.firstIndex(of: "["), let closeBracketIndex = title.firstIndex(of: "]") {
                            theTitle.removeSubrange(openBracketIndex...closeBracketIndex)
                            theTitle = theTitle.trimmingCharacters(in: .whitespaces)
                        }
                        
                        var dateString = ""
                        if let newDate = try? dateElement.text() {
                            dateString = newDate
                        }
                        
                        let singleViewModel = RTRSSinglePodViewModel(title: theTitle, date: dateString, description: podDescription, imageURL: URL(string: imageAttribute))
                        self.content.append(singleViewModel)
                    }
                }
                self.completion?(self)
            } catch {
                print("Error parsing multi pod view model")
            }
        }
    }
}
