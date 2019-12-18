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
    let lastUpdate: Int
    var customCompletion: ((RTRSViewModel?) -> ())?
    
    required init(urls: [URL], pageName: String, type: String, lastUpdate: Int) {
        self.urls = urls
        self.pageName = pageName
        self.type = type
        self.lastUpdate = lastUpdate
        
        super.init()
    }
    
    override func start() {
        guard let firstUrl = self.urls.first else { return }
            
        func retrieveSavedDataIfAvailable() {
            if let type = RTRSScreenType(rawValue: self.pageName) {
                var viewModel: RTRSViewModel?
                
                print("Retrieving \(type.rawValue) from saved data")
                if type == .pod || type == .auArticle {
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
        let keyName = "\(self.pageName)-\(RTRSUserDefaultsKeys.lastUpdated)"
        let updated = UserDefaults.standard.integer(forKey: keyName)
        if updated < self.lastUpdate {
            UserDefaults.standard.set(self.lastUpdate, forKey: keyName)
            shouldUpdate = true
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
                            viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls, completionHandler: self.customCompletion)
                            deferredCompletion = true
                        } else {
                            viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls)
                        }
                        	
                        if let theViewModel = viewModel {
                            DispatchQueue.main.async {
                                RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                                RTRSPersistentStorage.save(viewModel: theViewModel, type: type)
                            }
                            
                            if !deferredCompletion {
                                self.customCompletion?(viewModel)
                            }
                        } else {
                            retrieveSavedDataIfAvailable()
                        }
                    } else {
                        retrieveSavedDataIfAvailable()
                    }
                }
            } catch {
                print("Error?")
                retrieveSavedDataIfAvailable()
            }
        } else {
            retrieveSavedDataIfAvailable()
        }
    }
}

fileprivate class RTRSViewModelFactory {
    
    class func viewModelForType(name: String, doc: Document, urls: [URL]? = nil, completionHandler: ((RTRSViewModel?) -> ())? = nil) -> RTRSViewModel? {
        
        switch name {
        case RTRSScreenType.home.rawValue:
            return RTRSHomeViewModel(doc: doc, items: nil, name: name, announcement: nil)
        case RTRSScreenType.podSource.rawValue:
            return RTRSPodSourceViewModel(doc: doc, pods: nil)
        case RTRSScreenType.podcasts.rawValue:
            return RTRSMultiPodViewModel(urls: urls, name: name, pods: nil, completionHandler: completionHandler)
        case RTRSScreenType.au.rawValue:
            return AUCornerMultiArticleViewModel(urls: urls, name: name, articles: nil, completionHandler: completionHandler)
        case RTRSScreenType.processPups.rawValue:
            return RTRSProcessPupsViewModel(doc: doc, pups: nil, description: nil, imageURLs: nil, completion: completionHandler)
        case RTRSScreenType.about.rawValue:
            return RTRSAboutViewModel(doc: doc, name: name, imageUrl: nil, body: nil)
        case RTRSScreenType.newsletter.rawValue:
            return RTRSNewsletterViewModel(name: name, url: urls!.first!)
        case RTRSScreenType.shirts.rawValue:
            return RTRSTshirtStoreViewModel(name: name, url: urls!.first!)
        default:
            break
        }
        
        return nil
    }
}
