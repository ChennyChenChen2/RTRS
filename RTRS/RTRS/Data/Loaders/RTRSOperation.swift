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
    
    let urls: [URL]!
    let pageName: String!
    let type: String!
    var customCompletion: ((RTRSViewModel?) -> ())?
    
    required init(urls: [URL], pageName: String, type: String) {
        self.urls = urls
        self.pageName = pageName
        self.type = type
        super.init()
    }
    
    override func start() {
        guard let firstUrl = self.urls.first else { return }
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: "\(firstUrl.absoluteString)?format=json-pretty")!)
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let collectionDict = dict["collection"] as? [String: Any], let updated = collectionDict["updatedOn"] as? Int {
                
                let keyName = "\(self.pageName!)-\(RTRSUserDefaultsKeys.lastUpdated)"
                let lastUpdate = UserDefaults.standard.integer(forKey: keyName)
                if updated > lastUpdate {
//                if true {
                    UserDefaults.standard.set(updated, forKey: keyName)
                    do {
                        if let url = self.urls.first {
                            let htmlString = try String.init(contentsOf: url)
                            let doc = try SwiftSoup.parse(htmlString)
                            if let type = RTRSScreenType(rawValue: self.pageName) {
                                var viewModel: RTRSViewModel?
                                
                                if type == .au {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc, urls: self.urls)
                                } else {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc)
                                }
                                
                                if let theViewModel = viewModel {
                                    DispatchQueue.main.async {
                                        RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                                        RTRSPersistentStorage.save(viewModel: theViewModel, type: type)
                                    }
                                    self.customCompletion?(viewModel)
                                } else {
                                    self.customCompletion?(nil)
                                }
                            } else {
                                self.customCompletion?(nil)
                            }
                        }
                    } catch {
                        print("Error?")
                        self.customCompletion?(nil)
                    }
                } else {
                    if let type = RTRSScreenType(rawValue: self.pageName) {
                        var viewModel: RTRSViewModel?
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
            }
        }
        task.resume()
    }
}


fileprivate class RTRSViewModelFactory {
    
    class func viewModelForType(name: String, doc: Document, urls: [URL]? = nil) -> RTRSViewModel? {
        
        switch name {
        case "Home":
            return RTRSHomeViewModel(doc: doc, items: nil, name: name, announcement: nil)
        case "If Not, Pick Will Convey As Two Second-Rounders":
            return AUCornerMultiArticleViewModel(urls: urls, name: name, articles: nil)
        case "About":
            return RTRSAboutViewModel(doc: doc, name: name, imageUrl: nil, body: nil)
        default:
            break
        }
        
        return nil
    }
}
