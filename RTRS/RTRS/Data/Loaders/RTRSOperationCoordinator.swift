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
    
    func beginStartupProcess(dict: [String: Any], forceReload: Bool, completionHandler: @escaping (Bool) -> ()) { 
        self.processedOperations = 0
        
        if let pages = dict["pages"] as? [[String: Any]] {
            UserDefaults.standard.set(dict, forKey: RTRSUserDefaultsKeys.configStorage)
            self.operationCount = pages.count + 1 // +1 for Pod source
        
            let operationCompletion: (RTRSViewModel?) -> () = { [weak self] (viewModel) in
                DispatchQueue.main.async {
                    guard let weakSelf = self else {
                        completionHandler(false)
                        return
                    }
                    
                    if let theViewModel = viewModel, let type = RTRSScreenType(rawValue: theViewModel.pageName()) {
                        RTRSNavigation.shared.registerViewModel(viewModel: theViewModel, for: type)
                        if let name = viewModel?.loadedNotificationName() {
                            NotificationCenter.default.post(name: name, object: nil)
                        }
                    
                        print("\(viewModel?.pageName() ?? "<<MISSING NAME>>") successfully called custom completion")
                    } else {
                        print("\(viewModel?.pageName() ?? "<<MISSING NAME>>") CALLED COMPLETION WITH FAILURE")
                    }
                    
                    if let moreItems = dict["moreItems"] as? [String] {
                        var viewModels = [RTRSViewModel]()
                        for item in moreItems {
                            if let type = RTRSScreenType(rawValue: item),
                                let viewModel = RTRSNavigation.shared.viewModel(for: type) {
                                viewModels.append(viewModel)
                            }
                        }
                        
                        let savedContentVM = RTRSSavedContentViewModel()
                        RTRSNavigation.shared.registerViewModel(viewModel: savedContentVM, for: .saved)
                        viewModels.append(savedContentVM)
                        
                        let moreViewModel = RTRSMoreViewModel(pages: viewModels)
                        RTRSNavigation.shared.registerViewModel(viewModel: moreViewModel, for: .more)
                        if let name = moreViewModel.loadedNotificationName() {
                            NotificationCenter.default.post(name: name, object: nil)
                        }
                    }
                    
                    weakSelf.processedOperations = weakSelf.processedOperations + 1
                    if weakSelf.processedOperations == weakSelf.operationCount {
                        print("LOADING COMPLETE")
                        completionHandler(true)
                    }
                }
            }
        
            if let podSource = dict["podSource"] as? [String: Any],
                let podSourceURLString = podSource["url"] as? String,
                let podSourceURL = URL(string: podSourceURLString),
                let ignoreTitles = podSource["ignoreTitles"] as? [String]
            {
                let operation = RTRSOperation(urls: [podSourceURL], forceReload: forceReload, pageName: "Pod Source", type: "Pod Source", ignoreTitles: ignoreTitles)
                operation.customCompletion = operationCompletion
                self.operationQueue.addOperation(operation)
            }
                
            for page in pages {
                if let name = page["name"] as? String, let type = page["type"] as? String {
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
                    
                    var ignoreTitles = [String]()
                    if let titles = page["ignoreTitles"] as? [String] {
                        ignoreTitles = titles
                    }
                    
                    let operation = RTRSOperation(urls: urls, forceReload: forceReload, pageName: name, type: type, ignoreTitles: ignoreTitles)
                    operation.customCompletion = operationCompletion
                    self.operationQueue.addOperation(operation)
                }
            }
        }
    }
}
