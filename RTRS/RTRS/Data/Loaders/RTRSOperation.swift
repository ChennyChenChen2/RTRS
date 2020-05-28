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
    
    // TODO: override `asynchronous`, `executing`, and `finished`, per "Methods to Override" docs! https://developer.apple.com/documentation/foundation/operation
    override func start() {
//        guard let firstUrl = self.urls.first else { return }
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
                    return
                }
            }
            
            self.customCompletion?(nil)
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
                        UserDefaults.standard.set(lastUpdated, forKey: keyName)
                    }
                } else {
                    lastUpdated = headers["Etag"]
                    if let value = lastUpdated {
                        lastUpdated = value.replacingOccurrences(of: "--gzip", with: "")
                    }
                    
                    if updated != lastUpdated {
                        shouldUpdate = true
                        UserDefaults.standard.set(lastUpdated, forKey: keyName)
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
                               
                                if type == .au || type == .podcasts || type == .processPups {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls, ignoreTitles: self.ignoreTitles, completionHandler: self.customCompletion)
                                    deferredCompletion = true
                                } else {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls, ignoreTitles: self.ignoreTitles)
                                }
                                   
                                if !deferredCompletion {
                                    self.customCompletion?(viewModel)
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
    class func viewModelForType(name: String, doc: Document, urls: [URL]? = nil, ignoreTitles: [String]? = nil, completionHandler: ((RTRSViewModel?) -> ())? = nil) -> RTRSViewModel? {
        
        switch name {
        case RTRSScreenType.home.rawValue:
            return RTRSHomeViewModel(doc: doc, items: nil, name: name, announcement: nil, ignoreTitles: ignoreTitles ?? [])
        case RTRSScreenType.podSource.rawValue:
            return RTRSPodSourceViewModel(doc: doc, pods: nil, ignoreTitles: ignoreTitles)
        case RTRSScreenType.podcasts.rawValue:
            return RTRSMultiPodViewModel(urls: urls, name: name, pods: nil, ignoreTitles: ignoreTitles, completionHandler: completionHandler)
        case RTRSScreenType.au.rawValue:
            return MultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler)
        case RTRSScreenType.normalColumn.rawValue:
            return MultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler)
        case RTRSScreenType.processPups.rawValue:
            return RTRSProcessPupsViewModel(doc: doc, pups: nil, description: nil, imageURLs: nil, completion: completionHandler)
        case RTRSScreenType.about.rawValue:
            return RTRSAboutViewModel(doc: doc, name: name, imageUrl: nil, body: nil)
        case RTRSScreenType.newsletter.rawValue:
            guard let url = urls?.first else { return nil }
            return RTRSNewsletterViewModel(name: name, url: url)
        case RTRSScreenType.shirts.rawValue:
            guard let url = urls?.first else { return nil }
            return RTRSTshirtStoreViewModel(name: name, url: url)
        default:
            break
        }
        
        return nil
    }
}
