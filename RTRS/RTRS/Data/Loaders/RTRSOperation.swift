//
//  RTRSOperation.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/19/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import WebKit
import SwiftSoup

class RTRSOperation: Operation {
    
    enum State: String {
        case Ready, Executing, Finished

        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }
      
    var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    let urls: [URL]
    let pageName: String
    let type: String
    let ignoreTitles: [String]
    var customCompletion: ((RTRSViewModel?) -> ())?
    
    required init(urls: [URL], pageName: String, type: String, ignoreTitles: [String]) {
        self.urls = urls
        self.pageName = pageName
        self.type = type
        self.ignoreTitles = ignoreTitles
        
        super.init()
    }
    
    override func start() {
        if isCancelled {
          state = .Finished
          return
        }
        
        main()
        state = .Executing
    }
    
    override var isReady: Bool {
        return super.isReady && state == .Ready
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return state == .Executing
    }
    
    override var isFinished: Bool {
      return state == .Finished
    }
    
    override func cancel() {
        state = .Finished
    }
    
    override func main() {
        print("RTRS beginning to load \(pageName)")
            
        func retrieveSavedDataIfAvailable() {
            if let type = RTRSScreenType(rawValue: self.pageName) {
                var viewModel: RTRSViewModel?
                
                print("Retrieving \(type.rawValue) from saved data")
                if type == .pod || type == .auArticle || type == .normalColumnArticle {
                    viewModel = RTRSPersistentStorage.getViewModel(type: type, specificName: self.pageName)
                } else {
                    viewModel = RTRSPersistentStorage.getViewModel(type: type)
                }
                
                if let theViewModel = viewModel {
                    DispatchQueue.main.async {
                        RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                    }
                    self.customCompletion?(theViewModel)
                    self.state = .Finished
                    return
                }
            }
            
            self.customCompletion?(nil)
            self.state = .Finished
        }
            
        var shouldUpdate = false
        if let url = self.urls.first {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let response = response as? HTTPURLResponse,
                    let headers = response.allHeaderFields as? [String: String] else {
                    retrieveSavedDataIfAvailable()
                    return
                }
                
                let keyName = "\(self.pageName)-\(RTRSUserDefaultsKeys.lastUpdated)"
                let updated = UserDefaults.standard.string(forKey: keyName)
                var lastUpdated = headers["Last-Modified"]
                
                if lastUpdated != nil {
                    if updated != lastUpdated {
                        shouldUpdate = true
                    }
                } else {
                    lastUpdated = headers["Etag"]
                    if let value = lastUpdated {
                        lastUpdated = value.replacingOccurrences(of: "--gzip", with: "")
                    }
                    
                    if updated != lastUpdated {
                        shouldUpdate = true
                    }
                }
            
                if shouldUpdate {
                    do {
                        if let url = self.urls.first {
                            let htmlString = try String.init(contentsOf: url)
                            var doc: Document
                            if self.pageName == "Pod Source" {
                                doc = try SwiftSoup.parse(htmlString, "", Parser.xmlParser())
                            } else {
                                doc = try SwiftSoup.parse(htmlString)
                            }
                           
                            if let type = RTRSScreenType(rawValue: self.pageName) {
                                var viewModel: RTRSViewModel?
                                var deferredCompletion = false
                               
                                if type == .au || type == .podcasts || type == .normalColumn || type == .moc {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls, ignoreTitles: self.ignoreTitles, completionHandler: self.customCompletion, etag: lastUpdated)
                                    deferredCompletion = true
                                } else {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls, ignoreTitles: self.ignoreTitles)
                                }
                                   
                                if !deferredCompletion {
                                    UserDefaults.standard.set(lastUpdated, forKey: keyName)
                                    self.customCompletion?(viewModel)
                                    self.state = .Finished
                                }
                            } else {
                                // TODO: throw error for invalid page type...
                                // Call to retrieveSavedDataIfAvailable won't do anything because of the invalid page type
                                retrieveSavedDataIfAvailable()
                            }
                        }
                    } catch {
                        print("Error?")
                        // TODO: create meaningful html parsing error
                        retrieveSavedDataIfAvailable()
                    }
                } else {
                    // Fall here if we've determined we don't need to update existing data
                    retrieveSavedDataIfAvailable()
                }
            }
            
            task.resume()
        }
    }
}

fileprivate class RTRSViewModelFactory {
    class func viewModelForType(name: String, doc: Document, urls: [URL]? = nil, ignoreTitles: [String]? = nil, completionHandler: ((RTRSViewModel?) -> ())? = nil, etag: String? = nil) -> RTRSViewModel? {
        
        switch name {
        case RTRSScreenType.home.rawValue:
            return RTRSHomeViewModel(doc: doc, items: nil, name: name, announcement: nil, ignoreTitles: ignoreTitles ?? [])
        case RTRSScreenType.podSource.rawValue:
            return RTRSPodSourceViewModel(doc: doc, pods: nil, ignoreTitles: ignoreTitles)
        case RTRSScreenType.podcasts.rawValue:
            return RTRSMultiPodViewModel(urls: urls, name: name, pods: nil, ignoreTitles: ignoreTitles, completionHandler: completionHandler, etag: etag)
        case RTRSScreenType.au.rawValue:
            return MultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler, etag: etag)
        case RTRSScreenType.normalColumn.rawValue:
            return MultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler, etag: etag)
        case RTRSScreenType.moc.rawValue:
            return MultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler, etag: etag)
        case RTRSScreenType.processPups.rawValue:
            return RTRSProcessPupsViewModel(doc: doc, pups: nil, description: nil, imageURLs: nil, completion: completionHandler, etag: etag)
        case RTRSScreenType.goodDogClub.rawValue:
            return RTRSGoodBoyClubViewModel(doc: doc, pups: nil, description: nil, imageURLs: nil, completion: completionHandler, etag: etag)
        case RTRSScreenType.abbie.rawValue:
            return RTRSAbbieArtGalleryViewModel(doc: doc, entries: nil, description: nil, imageURLs: nil, completion: completionHandler, etag: etag)
        case RTRSScreenType.about.rawValue:
            return RTRSAboutViewModel(doc: doc, name: name, imageUrl: nil, bodyHTML: nil)
        case RTRSScreenType.newsletter.rawValue:
            guard let url = urls?.first else { return nil }
            return RTRSNewsletterViewModel(name: name, url: url)
        case RTRSScreenType.shirts.rawValue:
            guard let url = urls?.first else { return nil }
            return RTRSTshirtStoreViewModel(name: name, url: url)
        case RTRSScreenType.sponsors.rawValue:
            return RTRSSponsorsViewModel(doc: doc, sponsorDescription: nil, sponsors: nil)
        default:
            break
        }
        
        return nil
    }
}
