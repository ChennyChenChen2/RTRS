//
//  AUCornerMultiArticleViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

protocol MultiContentViewModel {
    var content: [SingleContentViewModel] { get }
}

class AUCornerMultiArticleViewModel: NSObject, RTRSViewModel, MultiContentViewModel {
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return self.name ?? "AU's Corner"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "RickyLogo")
    }
    
    enum CodingKeys: String {
        case name = "Name"
        case articles = "Articles"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.content, forKey: CodingKeys.articles.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let articles = aDecoder.decodeObject(forKey: CodingKeys.articles.rawValue) as? [AUCornerSingleArticleViewModel]
        
        self.init(urls: nil, name: name, articles: articles, completionHandler: nil)
    }

    let name: String?
    var content: [SingleContentViewModel]  = [AUCornerSingleArticleViewModel]()
    var completion: ((RTRSViewModel?) -> ())?

    required init(urls: [URL]?, name: String?, articles: [AUCornerSingleArticleViewModel]?, completionHandler: ((RTRSViewModel?) -> ())?) {
        self.name = name
        self.content = articles ?? []
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
                        let articleDescription = try? descriptionTextElement.text(),
                        let imageAttribute = try? imageElement.attr("data-asset-url")
                    {
                        
                        guard let encodedUrlSuffix = urlSuffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                        let articleUrl = URL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else { continue }
                        
                        if let dateAElem = try? dateElement.getElementsByTag("a").first() {
                            try dateAElem.remove()
                        }
                        
                        var dateString = ""
                        if let newDate = try? dateElement.text() {
                            dateString = newDate
                        }
                        
                        let htmlString = try String.init(contentsOf: articleUrl)
                        let articleDoc = try SwiftSoup.parse(htmlString)
                        let singleArticleViewModel = AUCornerSingleArticleViewModel(doc: articleDoc, title: title, articleDescription: articleDescription, baseURL: articleUrl, dateString: dateString, imageUrl: URL(string: imageAttribute), htmlString: nil)
                        content.append(singleArticleViewModel)
                    }
                }
            } catch {
                print("Error parsing AU's Corner view model")
                break
            }
        }
        
        print("FINISHED LOADING AU CORNER MULTI-ARTICLE")
        self.completion?(self)
    }
}
