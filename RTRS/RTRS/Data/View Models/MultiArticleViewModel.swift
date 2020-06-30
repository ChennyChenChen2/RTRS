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
    var content: [SingleContentViewModel?] { get }
}

class MultiArticleViewModel: NSObject, RTRSViewModel, MultiContentViewModel {
    
    func loadedNotificationName() -> Notification.Name? {
        return (self.pageName() == "AU's Corner") ? .auLoadedNotificationName : .normalColumnLoadedNotificationName
    }
    
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
        let articles = aDecoder.decodeObject(forKey: CodingKeys.articles.rawValue) as? [SingleArticleViewModel]
        
        self.init(urls: nil, name: name, articles: articles, completionHandler: nil)
    }

    let name: String?
    var content: [SingleContentViewModel?]  = [SingleArticleViewModel]()
    var completion: ((RTRSViewModel?) -> ())?
    
    private let group = DispatchGroup()

    required init(urls: [URL]?, name: String?, articles: [SingleArticleViewModel]?, completionHandler: ((RTRSViewModel?) -> ())?) {
        self.name = name
        self.content = articles ?? []
        self.completion = completionHandler
        
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls else {
            self.completion?(self)
            return
        }
        
        var batchDict = [Int: [SingleContentViewModel?]]()
        
        let concurrentQueue = DispatchQueue(label: "com.queue.concurrent", attributes: .concurrent)
        self.group.enter()
        for n in 0..<theURLs.count {
            concurrentQueue.async {
                self.group.notify(queue: .main) {
                    print("FINISHED LOADING \(self.pageName())")
                    let batches = batchDict.sorted { $0.key < $1.key }
                    for (_, v) in batches {
                        self.content.append(contentsOf: v.compactMap { $0 })
                    }
                    
                    self.completion?(self)
                    return
                }
                
                do {
                    let url = theURLs[n]
                    let htmlString = try String.init(contentsOf: url)
                    let doc = try SwiftSoup.parse(htmlString)
                    let postElements = try doc.getElementsByTag("article")
                    var batch = [SingleArticleViewModel?](repeating: nil, count: postElements.count)
                    for i in 0..<postElements.count {
                        concurrentQueue.async {
                            let postElement = postElements[i]
                            
                            var theTitleElem: Element? = try? postElement.getElementsByClass("title").first()
                            if theTitleElem == nil {
                                theTitleElem = try? postElement.getElementsByClass("entry-title").first()
                            }
                        
                            var theDateElem: Element? = try? postElement.getElementsByClass("date-author").first()
                            if theDateElem == nil {
                                theDateElem = try? postElement.getElementsByClass("date").first()
                            }
                        
                            do {
                                let imageElement = try postElement.getElementsByClass("squarespace-social-buttons inline-style")
                                if let titleElement = theTitleElem,
                                    let aElement = try? titleElement.getElementsByTag("a").first(),
                                    let dateElement = theDateElem,
                                    let title = try? aElement.text(),
                                    let urlSuffix = try? aElement.attr("href"),
                                    let descriptionTextElement = try? postElement.getElementsByTag("p").first(),
                                    let articleDescription = try? descriptionTextElement.text(),
                                    let imageAttribute = try? imageElement.attr("data-asset-url")
                                {
                                
                                    guard let encodedUrlSuffix = urlSuffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                                        let articleUrl = URL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else { return }
                                    
                                    var dateString = ""
                                    if let newDate = try? dateElement.text() {
                                        dateString = newDate
                                    }
                                    
                                    let htmlString = try String.init(contentsOf: articleUrl)
                                    let articleDoc = try SwiftSoup.parse(htmlString)
                                    let singleArticleViewModel = SingleArticleViewModel(doc: articleDoc, title: title, articleDescription: articleDescription, baseURL: articleUrl, dateString: dateString, imageUrl: URL(string: imageAttribute), htmlString: nil)
                                    batch[i] = singleArticleViewModel
                                        
            //                                    outerQueue.sync { [weak self] in
            //                                        self?.content.append(singleArticleViewModel)

                                    if i == postElements.count - 1 {
                                        batchDict[n] = batch
                                        if n == theURLs.count - 1 {
                                            self.group.leave()
                                        }
                                    }
                                }
                            } catch {
                                print("Error parsing \(self.pageName()) view model")
                                return
                            }
                        }
                    }
                } catch {
                    print("Error parsing \(self.pageName()) view model")
                    return
                }
            }
        }
    }
}
