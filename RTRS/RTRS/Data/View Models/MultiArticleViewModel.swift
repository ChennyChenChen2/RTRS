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
        case shouldReload = "ShouldReload"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(self.content, forKey: CodingKeys.articles.rawValue)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        let articles = aDecoder.decodeObject(forKey: CodingKeys.articles.rawValue) as? [SingleArticleViewModel]
        
        self.init(urls: nil, name: name, articles: articles, completionHandler: nil, etag: nil, ignoreTitles: nil, existingContent: nil)
    }

    let name: String?
    var content: [SingleContentViewModel?]  = [SingleArticleViewModel]()
    var completion: ((RTRSViewModel?) -> ())?
    let etag: String?
    var ignoreTitles: [String]?
    var existingContent = [SingleArticleViewModel]()
    
    private let group = DispatchGroup()

    required init(urls: [URL]?, name: String?, articles: [SingleArticleViewModel]?, completionHandler: ((RTRSViewModel?) -> ())?, etag: String?, ignoreTitles: [String]?, existingContent: [SingleArticleViewModel]?) {
        self.name = name
        self.content = articles ?? []
        self.completion = completionHandler
        self.etag = etag
        self.existingContent = existingContent ?? []
        self.ignoreTitles = ignoreTitles ?? []
        
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls else {
            self.completion?(self)
            return
        }
        
        self.content.append(contentsOf: self.existingContent)
        self.ignoreTitles?.append(contentsOf: self.content.map { $0?.title ?? "" })
        
        var batchDict = ThreadSafeDict<Int, [SingleContentViewModel?]>()
        let concurrentQueue = DispatchQueue(label: "com.articles.queue.concurrent", attributes: .concurrent)
        self.group.enter()
        for n in 0..<theURLs.count {
            let url = theURLs[n]
            concurrentQueue.async {
                do {
                    let innerQueue = DispatchQueue(label: "com.articles.queue.inner", attributes: .concurrent)
                    let htmlString = try String.init(contentsOf: url)
                    let doc = try SwiftSoup.parse(htmlString)
                    let postElements = try doc.getElementsByTag("article")
                    print("\(self.pageName()): Batch \(n) has \(postElements.count) posts")
                    var batch = [SingleArticleViewModel?]()
                    for i in 0..<postElements.count {
                        innerQueue.async {
                            func wrapUp(_ singleArticleVM: SingleArticleViewModel?) {
                                batch.append(singleArticleVM)
                                
                                if batch.count == postElements.count {
                                    print("\(self.pageName()): COMPLETED BATCH \(n), CONTAINS \(batch.filter({ $0 != nil }).count)")
                                    batchDict.setValue(batch, for: n)
                                    batchDict.count { (count) in
                                        if count == theURLs.count {
                                            self.group.leave()
                                            return
                                        }
                                    }
                                }
                            }
                            
                            let postElement = postElements[i]
                            
                            var theTitleElem: Element? = try? postElement.getElementsByClass("title").first()
                            if theTitleElem == nil {
                                theTitleElem = try? postElement.getElementsByClass("entry-title").first()
                            }
                        
                            var theDateElem: Element? = try? postElement.getElementsByClass("date-author").first()
                            if theDateElem == nil {
                                theDateElem = try? postElement.getElementsByClass("date").first()
                            }
                        
                            let imageElement = try? postElement.getElementsByClass("squarespace-social-buttons inline-style")
                            if let titleElement = theTitleElem,
                                let aElement = try? titleElement.getElementsByTag("a").first(),
                                let dateElement = theDateElem,
                                let title = try? aElement.text(),
                                let urlSuffix = try? aElement.attr("href"),
                                let descriptionTextElement = try? postElement.getElementsByTag("p").first(),
                                let articleDescription = try? descriptionTextElement.text(),
                                let imageAttribute = try? imageElement?.attr("data-asset-url")
                            {
                                guard let encodedUrlSuffix = urlSuffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                                    let articleUrl = NSURL(string: "https://www.rightstorickysanchez.com\(encodedUrlSuffix)") else {
                                        print("error with URL encoding... offending URL suffix: \(urlSuffix)")
                                        wrapUp(nil)
                                        return
                                }
                                
                                if let titles = self.ignoreTitles, titles.contains(title) {
                                    print("IGNORING: \(title)")
                                    wrapUp(nil)
                                    return
                                }
                                
                                var dateString = ""
                                if let newDate = try? dateElement.text() {
                                    dateString = newDate
                                }

                                let singleArticleViewModel = SingleArticleViewModel(doc: nil, title: title, articleDescription: articleDescription, baseURL: articleUrl, dateString: dateString, imageUrl: NSURL(string: imageAttribute), htmlString: nil)

                                wrapUp(singleArticleViewModel)
                                return
                            } else {
                                print("Multi-article: something went wrong?")
                                wrapUp(nil)
                                return
                            }
                        }
                    }
                } catch let error {
                    print("Error parsing \(self.pageName()) view model: \(error.localizedDescription)")
                    self.completion?(nil)
                    return
                }
            }
        }
        
        self.group.notify(queue: .main) {
            batchDict.dictRepresentation { [weak self] (dict) in
                guard let self = self else { return }
                print("FINISHED LOADING \(self.pageName()), \(dict.count) entries")
                let batches = dict.sorted { $0.key < $1.key }
                for (_, v) in batches {
                    self.content.append(contentsOf: v.compactMap { $0 })
                }
                
                if let etag = self.etag {
                    let keyName = "\(self.pageName())-\(RTRSUserDefaultsKeys.lastUpdated)"
                    UserDefaults.standard.set(etag, forKey: keyName)
                }
                
                self.content.sort { (vm1, vm2) -> Bool in
                    guard let dateString1 = vm1?.dateString, let dateString2 = vm2?.dateString else { return false }
                    let dateFormatter = DateFormatter()
                    // "OCTOBER 24, 2020"
                    dateFormatter.dateFormat = "MMMM dd, yyyy"
                    guard let date1 = dateFormatter.date(from: dateString1), let date2 = dateFormatter.date(from: dateString2) else { return false }
                    
                    return date1.compare(date2) == .orderedDescending
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
            response(dict.compactMap { $0 }.count)
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
