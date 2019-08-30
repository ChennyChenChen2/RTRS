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
    
    let url: URL!
    let pageName: String!
    let type: String!
    var viewModel: Any?
    var customCompletion: ((RTRSViewModel?) -> ())?
    
    required init(url: URL, pageName: String, type: String) {
        self.url = url
        self.pageName = pageName
        self.type = type
        super.init()
    }
    
    override func start() {
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: "\(self.url.absoluteString)?format=json-pretty")!)
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let collectionDict = dict["collection"] as? [String: Any], let updated = collectionDict["updatedOn"] as? Int {
                
                let keyName = "\(self.pageName!)-\(RTRSUserDefaultsKeys.lastUpdated)"
                let lastUpdate = UserDefaults.standard.integer(forKey: keyName)
//                if updated > lastUpdate {
                if true {
                    UserDefaults.standard.set(updated, forKey: keyName)
                    do {
                        let htmlString = try String.init(contentsOf: self.url)
                        let doc = try SwiftSoup.parse(htmlString)
                        if let viewModel = RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc),
                            let type = RTRSScreenType(rawValue: self.pageName) {
                            RTRSNavigation.shared.registerViewModel(viewModel: viewModel, for: type)
                            self.customCompletion?(viewModel)
                        } else {
                            self.customCompletion?(nil)
                        }
                    } catch {
                        print("Error?")
                        self.customCompletion?(nil)
                    }
                } else {
                    guard let html = UserDefaults.standard.string(forKey: "\(self.pageName!)-\(RTRSUserDefaultsKeys.htmlStorage)") else {
                        // TODO: Retrieve persisted view model for the given type
                        self.customCompletion?(nil)
                        return
                    }
                    
                    do {
                        let doc = try SwiftSoup.parse(html)
                        self.customCompletion?(RTRSViewModelFactory.viewModelForType(name: self.pageName, doc: doc))
                        print("HERE!")
                    } catch Exception.Error(let type, let message) {
                        print("\(message)... TYPE: \(type)")
                        self.customCompletion?(nil)
                    } catch {
                        print("error")
                        self.customCompletion?(nil)
                    }
                
                }
            }
        }
        task.resume()
    }
}


fileprivate class RTRSViewModelFactory {
    
    class func viewModelForType(name: String, doc: Document) -> RTRSViewModel? {
        
        switch name {
        case "Home":
            return RTRSHomeViewModel(doc: doc, items: nil, name: name, announcement: nil)
        case "If Not, Pick Will Convey As Two Second-Rounders":
            return AUCornerMultiArticleViewModel(doc: doc, name: name, articles: nil)
        case "About":
            return RTRSAboutViewModel(doc: doc, name: name, image: nil, body: nil)
        default:
            break
        }
        
        
        
        
        return nil
    }
}
