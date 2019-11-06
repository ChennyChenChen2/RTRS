//
//  RTRSOperationCoordinator.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/19/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation

class RTRSOperationCoordinator {
    
    let operationQueue = OperationQueue()
    var observation: NSKeyValueObservation?
    var operationCount: Int = 0
    var processedOperations: Int = 0
    @objc var finishedOperations = [RTRSOperation]()
    
    func beginStartupProcess(dict: [String: Any]?, completionHandler: @escaping (Bool) -> ()) {
        self.operationQueue.maxConcurrentOperationCount = 100
        
        var configDict: [String: Any]?
        
        if let theDict = dict {
            configDict = theDict
        } else {
            // First try to get saved config
            // REMEMBER TO REMOVE "if false"!!!!!
            if false, let data = try? Data(contentsOf: LoadingViewController.cachedConfigPath),
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                configDict = dict
            }
                
            // Last resort: bundled config
            else if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json") {
                let configUrl = URL(fileURLWithPath: configPath)
                if let configData = try? Data(contentsOf: configUrl),
                    let theConfigDict = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any] {
                    configDict = theConfigDict
                }
            }
        }
        
        if let theConfigDict = configDict, let pages = theConfigDict["pages"] as? [[String: Any]] {
            UserDefaults.standard.set(configDict, forKey: RTRSUserDefaultsKeys.configStorage)
            self.operationCount = pages.count + 1 // +1 for Pod source
        
            let operationCompletion: (RTRSViewModel?) -> () = { [weak self] (viewModel) in
                DispatchQueue.main.async {
                    guard let weakSelf = self else {
                        completionHandler(false)
                        return
                    }
                    
                    weakSelf.processedOperations = weakSelf.processedOperations + 1
                    if weakSelf.processedOperations == weakSelf.operationCount {
                        if let moreItems = theConfigDict["moreItems"] as? [String] {
                            var viewModels = [RTRSViewModel]()
                            for item in moreItems {
                                if let type = RTRSScreenType(rawValue: item),
                                    let viewModel = RTRSNavigation.shared.viewModel(for: type){
                                    viewModels.append(viewModel)
                                }
                            }
                            let moreViewModel = RTRSMoreViewModel(pages: viewModels)
                            RTRSNavigation.shared.registerViewModel(viewModel: moreViewModel, for: .more)
                        }
                        
                        print("LOADING COMPLETE")
                        completionHandler(true)
                    }
                }
            }
        
            if let podSource = theConfigDict["podSource"] as? [String: Any],
                let podSourceURLString = podSource["url"] as? String,
                let podSourceURL = URL(string: podSourceURLString), let lastUpdate = podSource["lastUpdate"] as? Int
            {
                let operation = RTRSOperation(urls: [podSourceURL], pageName: "Pod Source", type: "Pod Source", lastUpdate: lastUpdate)
                operation.customCompletion = operationCompletion
                self.operationQueue.addOperation(operation)
            }
                
            for page in pages {
                if let name = page["name"] as? String, let type = page["type"] as? String, let lastUpdate = page["lastUpdate"] as? Int {
                    var urls = [URL]()
                    if let urlString = page["link"] as? String, let url = URL(string: urlString) {
                       urls.append(url)
                    } else if let urlStrings = page["links"] as? [String] {
                        urlStrings.forEach { (urlString) in
                            if let url = URL(string: urlString) {
                                urls.append(url)
                            }
                        }
                    }
                    
                    let operation = RTRSOperation(urls: urls, pageName: name, type: type, lastUpdate: lastUpdate)
                    operation.customCompletion = operationCompletion
                    self.operationQueue.addOperation(operation)
                }
            }
        }
    }
}
