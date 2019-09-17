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
        let task = urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            
            guard let weakSelf = self else { return }
            
            func retrieveSavedDataIfAvailable() {
                if let type = RTRSScreenType(rawValue: weakSelf.pageName) {
                    var viewModel: RTRSViewModel?
                    if type == .pod || type == .auArticle {
                        viewModel = RTRSPersistentStorage.getViewModel(type: type, specificName: weakSelf.pageName)
                    } else {
                        viewModel = RTRSPersistentStorage.getViewModel(type: type)
                    }
                    if let theViewModel = viewModel {
                        DispatchQueue.main.async {
                            RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                        }
                        weakSelf.customCompletion?(theViewModel)
                        return
                    }
                }
                
                weakSelf.customCompletion?(nil)
            }
            
            
            if let error = error {
                print(error.localizedDescription)
                // TODO: create error VC to kill app/tell user to reopen app if all else fails
                if error.localizedDescription.contains("The Internet connection appears to be offline") {
                    retrieveSavedDataIfAvailable()
                }
            }
            
            if let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let collectionDict = dict["collection"] as? [String: Any], let updated = collectionDict["updatedOn"] as? Int {
                
                let keyName = "\(weakSelf.pageName!)-\(RTRSUserDefaultsKeys.lastUpdated)"
                let lastUpdate = UserDefaults.standard.integer(forKey: keyName)
//                if updated > lastUpdate {
                if false {
                    UserDefaults.standard.set(updated, forKey: keyName)
                    do {
                        if let url = weakSelf.urls.first {
                            let htmlString = try String.init(contentsOf: url)
                            let doc = try SwiftSoup.parse(htmlString)
                            if let type = RTRSScreenType(rawValue: weakSelf.pageName) {
                                var viewModel: RTRSViewModel?
                                
                                if type == .au {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: weakSelf.pageName, doc: doc, urls: weakSelf.urls)
                                } else {
                                    viewModel = RTRSViewModelFactory.viewModelForType(name: weakSelf.pageName, doc: doc)
                                }
                                
                                if let theViewModel = viewModel {
                                    DispatchQueue.main.async {
                                        RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                                        RTRSPersistentStorage.save(viewModel: theViewModel, type: type)
                                    }
                                    weakSelf.customCompletion?(viewModel)
                                } else {
                                    weakSelf.customCompletion?(nil)
                                }
                            } else {
                                weakSelf.customCompletion?(nil)
                            }
                        }
                    } catch {
                        print("Error?")
                        weakSelf.customCompletion?(nil)
                    }
                } else {
                    retrieveSavedDataIfAvailable()
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
