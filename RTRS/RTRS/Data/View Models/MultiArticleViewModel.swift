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
        guard let name = self.name else { return nil }
        switch name {
        case RTRSScreenType.au.rawValue: return .auLoadedNotificationName
        case RTRSScreenType.normalColumn.rawValue: return .normalColumnLoadedNotificationName
        case RTRSScreenType.moc.rawValue: return .mocLoadedNotificationName
        default: return nil
        }
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func pageName() -> String {
        return self.name ?? "If Not, Pick Will Convey As Two Second-Rounders"
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
        
        self.init(urls: nil, name: name, articles: articles, completionHandler: nil, etag: nil)
    }

    let name: String?
    var content: [SingleContentViewModel?]  = [SingleArticleViewModel]()
    var completion: ((RTRSViewModel?) -> ())?
    let etag: String?
    
    private let group = DispatchGroup()

    required init(urls: [URL]?, name: String?, articles: [SingleArticleViewModel]?, completionHandler: ((RTRSViewModel?) -> ())?, etag: String?) {
        self.name = name
        self.content = articles ?? []
        self.completion = completionHandler
        self.etag = etag
        
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls else {
            self.completion?(self)
            return
        }
        
//        var batchDict = [Int: [SingleContentViewModel?]]()
        var batchDict = ThreadSafeDict<Int, [SingleContentViewModel?]>()
        
        let concurrentQueue = DispatchQueue(label: "com.queue.concurrent", attributes: .concurrent)
        self.group.enter()
        for n in 0..<theURLs.count {
            concurrentQueue.async {
                do {
                    let innerQueue = DispatchQueue(label: "com.queue.inner", attributes: .concurrent)
                    let url = theURLs[n]
                    let htmlString = try String.init(contentsOf: url)
                    let doc = try SwiftSoup.parse(htmlString)
                    let postElements = try doc.getElementsByTag("article")
                    var batch = [SingleArticleViewModel?](repeating: nil, count: postElements.count)
                    var completed = 0
                    for i in 0..<postElements.count {
                        innerQueue.async {
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
                                        let articleUrl = URL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else {
                                            print("error with URL encoding... offending URL suffix: \(urlSuffix)")
                                            return
                                    }
                                    
                                    var dateString = ""
                                    if let newDate = try? dateElement.text() {
                                        dateString = newDate
                                    }
                                    
                                    let htmlString = try String.init(contentsOf: articleUrl)
                                    let articleDoc = try SwiftSoup.parse(htmlString)
                                    let singleArticleViewModel = SingleArticleViewModel(doc: articleDoc, title: title, articleDescription: articleDescription, baseURL: articleUrl, dateString: dateString, imageUrl: URL(string: imageAttribute), htmlString: nil)
                                    batch[i] = singleArticleViewModel

                                    completed += 1
                                    if completed == postElements.count {
                                        batchDict.setValue(batch, for: n)
                                        batchDict.count { (count) in
                                            if count == theURLs.count {
                                                self.group.leave()
                                            }
                                        }
                                    }
                                } else {
                                    print("Something went wrong?")
                                }
                            } catch let error {
                                print("Error parsing \(self.pageName()) view model: \(error.localizedDescription)")
                                return
                            }
                        }
                    }
                } catch let error {
                    print("Error parsing \(self.pageName()) view model: \(error.localizedDescription)")
                    return
                }
            }
        }
        
        self.group.notify(queue: .main) {
            print("FINISHED LOADING \(self.pageName())")
            batchDict.dictRepresentation { (dict) in
                let batches = dict.sorted { $0.key < $1.key }
                for (_, v) in batches {
                    self.content.append(contentsOf: v.compactMap { $0 })
                }

                if let etag = self.etag {
                    let keyName = "\(self.pageName())-\(RTRSUserDefaultsKeys.lastUpdated)"
                    UserDefaults.standard.set(etag, forKey: keyName)
                }
                
                self.completion?(self)
            }
        }
    }
}

struct ThreadSafeDict<Key: Hashable, Value> {
    private var dict = [Key: Value]()
    private let queue = DispatchQueue.global()
    
    func count(_ response: (Int)->()) {
        queue.sync {
            response(dict.count)
        }
    }
    
    func getValue(for key: Key, response: (Value?)->()) {
        queue.sync {
            response(dict[key])
        }
    }
    
    mutating func setValue(_ value: Value, for key: Key) {
        queue.sync {
            self.dict[key] = value
        }
    }
    
    func dictRepresentation(_ response: ([Key: Value])->()) {
        queue.sync {
            response(dict)
        }
    }
}
