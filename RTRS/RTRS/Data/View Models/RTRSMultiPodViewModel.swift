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
    func loadedNotificationName() -> Notification.Name? {
        return .podLoadedNotificationName
    }
    
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
        
        self.init(urls: nil, name: name, pods: pods, ignoreTitles: nil, completionHandler: nil, etag: nil, existingPods: nil)
    }
    
    let name: String?
    let etag: String?
    var content: [SingleContentViewModel?] = [RTRSSinglePodViewModel?]()
    var completion: ((RTRSViewModel?) -> ())?
    var ignoreTitles: [String]?
    var existingPods = [RTRSSinglePodViewModel]()

    required init(urls: [URL]?, name: String?, pods: [RTRSSinglePodViewModel]?, ignoreTitles: [String]?, completionHandler: ((RTRSViewModel?) -> ())?, etag: String?, existingPods: [RTRSSinglePodViewModel]?) {
        self.name = name
        self.etag = etag
        self.content = pods ?? []
        self.completion = completionHandler
        self.ignoreTitles = ignoreTitles ?? []
        self.existingPods = existingPods ?? []
        super.init()
        extractDataFromDoc(doc: nil, urls: urls)
    }
    
    private let group = DispatchGroup()
    
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        guard let theURLs = urls else {
            self.completion?(self)
            return
        }
        
        self.content.append(contentsOf: self.existingPods)
        self.ignoreTitles?.append(contentsOf: self.content.map { $0?.title ?? "" })
        
        var batchDict = ThreadSafeDict<Int, [SingleContentViewModel?]>()
        let concurrentQueue = DispatchQueue(label: "com.pods.queue.concurrent", attributes: .concurrent)
        self.group.enter()
        for batchNum in 0..<theURLs.count {
            let url = theURLs[batchNum]
            concurrentQueue.async {
                do {
                    let innerQueue = DispatchQueue(label: "com.pods.queue.inner", attributes: .concurrent)
                    let htmlString = try String.init(contentsOf: url)
                    let doc = try SwiftSoup.parse(htmlString)
                    let postElements = try doc.getElementsByTag("article")
                    print("Multi-Pod: Batch \(batchNum) has \(postElements.count) posts")
                    var batch = [RTRSSinglePodViewModel?]()
                    for i in 0..<postElements.count {
                        innerQueue.async {
                            func wrapUp(_ result: RTRSSinglePodViewModel?) {
                                batch.append(result)
                                
                                if batch.count == postElements.count {
                                    print("MULTI-POD: COMPLETED BATCH \(batchNum), CONTAINS \(batch.filter({ $0 != nil }).count)")
                                    batchDict.setValue(batch, for: batchNum)
                                    batchDict.count { (count) in
                                        if count == theURLs.count {
                                            self.group.leave()
                                            return
                                        }
                                    }
                                }
                            }
                            
                            let postElement = postElements[i]
                            let imageElement = try? postElement.getElementsByClass("squarespace-social-buttons inline-style")
                            var theTitleElem: Element? = try? postElement.getElementsByClass("title").first()
                            if theTitleElem == nil {
                                theTitleElem = try? postElement.getElementsByClass("entry-title").first()
                            }
                            
                            if let titleElem = theTitleElem, let title = try? titleElem.text(), title == "Copy of Sample RTRS Post To Duplicate" {
                                print("Skipping \(title)!")
                                wrapUp(nil)
                                return
                            }
                            
                            var theDateElem: Element? = try? postElement.getElementsByClass("date-author").first()
                            if theDateElem == nil {
                                theDateElem = try? postElement.getElementsByClass("date").first()
                            }
                            
                            if let titleElement = theTitleElem,
                                let aElement = try? titleElement.getElementsByTag("a").first(),
                                let dateElement = theDateElem,
                                let title = try? aElement.text(),
                                let sharingUrlString = try? aElement.attr("href"),
                                let sharingUrl = NSURL(string: "https://www.rightstorickysanchez.com\(sharingUrlString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)"),
                                let descriptionTextElement = try? postElement.getElementsByTag("p").first(),
                                let podDescription = try? descriptionTextElement.text(),
                                let imageAttribute = try? imageElement?.attr("data-asset-url")
                            {
                                #if DEBUG
                                if title == "Shake At The Point, and Larry Hughes On Iverson, LeBron, The Bubble and The Nelly Video" {
                                    wrapUp(nil)
                                    return
                                }
                                #endif
                                
                                var theTitle = title
                                if let openBracketIndex = title.firstIndex(of: "["), let closeBracketIndex = title.firstIndex(of: "]") {
                                    theTitle.removeSubrange(openBracketIndex...closeBracketIndex)
                                    theTitle = theTitle.trimmingCharacters(in: .whitespaces)
                                }
                                
                                if let titles = self.ignoreTitles, titles.contains(theTitle) {
                                    print("IGNORING: \(theTitle)")
                                    wrapUp(nil)
                                    return
                                }
                                
                                var dateString = ""
                                if let newDate = try? dateElement.text() {
                                    dateString = newDate
                                }
                                
                                let singleViewModel = RTRSSinglePodViewModel(doc: nil, title: theTitle, date: dateString, description: podDescription, imageURL: NSURL(string: imageAttribute), sharingUrl: sharingUrl, youtubeUrl: nil)
                                
                                wrapUp(singleViewModel)
                                return
                            } else {
                                print("Multi-pod: something went wrong? URL: \(url.absoluteString)")
                                wrapUp(nil)
                                return
                            }
                        }
                    }
                } catch let error {
                    print("Error parsing multi pod view model: \(error.localizedDescription)")
                }
            }
        }

        self.group.notify(queue: .main) {
            print("FINISHED LOADING MULTI-POD")
            batchDict.dictRepresentation { [weak self] (dict) in
                guard let self = self else { return }
                let batches = dict.sorted { $0.key < $1.key }
                for (_, v) in batches {
                    self.content.append(contentsOf: v.compactMap { $0 })
                }
                
                if let etag = self.etag {
                    let keyName = "\(self.pageName())-\(RTRSUserDefaultsKeys.lastUpdated)"
                    UserDefaults.standard.set(etag, forKey: keyName)
                }
                
                self.resortPods()
                self.completion?(self)
            }
        }
    }
    
    func resortPods() {
        self.content.sort { (vm1, vm2) -> Bool in
            guard let dateString1 = vm1?.dateString, let dateString2 = vm2?.dateString else { return false }
            let dateFormatter = DateFormatter()
            // "OCTOBER 24, 2020"
            dateFormatter.dateFormat = "MMMM dd, yyyy"
            guard let date1 = dateFormatter.date(from: dateString1), let date2 = dateFormatter.date(from: dateString2) else { return false }
            
            return date1.compare(date2) == .orderedDescending
        }
    }
}
