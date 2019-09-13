//
//  AUCornerMultiArticleViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class AUCornerMultiArticleViewModel: NSObject, RTRSViewModel {
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
        aCoder.encode(self.articles, forKey: CodingKeys.articles.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let articles = aDecoder.decodeObject(forKey: CodingKeys.articles.rawValue) as? [AUCornerSingleArticleViewModel]
        
        self.init(urls: nil, name: name, articles: articles)
    }

    let name: String?
    var articles = [AUCornerSingleArticleViewModel]()

    required init(urls: [URL]?, name: String?, articles: [AUCornerSingleArticleViewModel]?) {
        self.name = name
        self.articles = articles ?? []
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls, let firstURL = theURLs.first else { return }
        
        for url in theURLs {
            do {
                let htmlString = try String.init(contentsOf: url)
                let doc = try SwiftSoup.parse(htmlString)
                let postElements = try doc.getElementsByClass("post")
                let imageElements = try doc.getElementsByClass("main-image")
                for i in 0..<postElements.count {
                    let postElement = postElements[i]
                    let imageElement = imageElements[i]
                    if let titleElement = try? postElement.getElementsByClass("entry-title").first(),
                        let aElement = try? titleElement.getElementsByTag("a").first(),
                        let descriptionElement = try? postElement.getElementsByClass("body").first(),
                        let dateElement = try? postElement.getElementsByClass("published").first(),
                        let title = try? aElement.text(),
                        let urlSuffix = try? aElement.attr("href"),
                        let date = try? dateElement.text(),
                        let descriptionTextElement = try? descriptionElement.getElementsByTag("p").first(),
                        let articleDescription = try? descriptionTextElement.text(),
                        let imageAttribute = try? imageElement.attr("style"),
                        let openParenIndex = imageAttribute.firstIndex(of: "("),
                        let imageEndIndex = imageAttribute.lastIndex(of: "?")
                    {
                        let imageStartIndex = imageAttribute.index(after: openParenIndex)
                        let substring = imageAttribute[imageStartIndex..<imageEndIndex]
                        
                        guard let encodedUrlSuffix = urlSuffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                        let articleUrl = URL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else { return }
                        
                        let htmlString = try String.init(contentsOf: articleUrl)
                        let articleDoc = try SwiftSoup.parse(htmlString)
                        let singleArticleViewModel = AUCornerSingleArticleViewModel(doc: articleDoc, title: title, articleDescription: articleDescription, baseURL: articleUrl, dateString: date, imageUrl: URL(string: String(substring)), htmlString: nil)
                        articles.append(singleArticleViewModel)
                    }
                }
            } catch {
                print("Error parsing AU's Corner view model")
            }
        }
    }
}
