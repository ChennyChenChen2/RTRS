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
    var viewModels = [RTRSViewModel]()
    
    func beginStartupProcess(completionHandler: @escaping (Bool) -> ()) {
        self.operationQueue.maxConcurrentOperationCount = 100
        
        if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json") {
            let configUrl = URL(fileURLWithPath: configPath)
            if let configData = try? Data(contentsOf: configUrl),
            let configDict = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any],
            let pages = configDict["pages"] as? [[String: Any]] {
                UserDefaults.standard.set(configDict, forKey: RTRSUserDefaultsKeys.configStorage)
                self.operationCount = pages.count
            
                let operationCompletion: (RTRSViewModel?) -> () = { [weak self] (viewModel) in
                    guard let weakSelf = self else {
                        completionHandler(false)
                        return
                    }
                    
                    if let theViewModel = viewModel {
                        self?.viewModels.append(theViewModel)
                    }
                    
                    print("HERE")
                    
                    weakSelf.processedOperations = weakSelf.processedOperations + 1
                    if weakSelf.processedOperations == weakSelf.operationCount {
                        
                        if let moreItems = configDict["moreItems"] as? [String] {
                            var viewModels = [RTRSViewModel]()
                            for item in moreItems {
                                if let type = RTRSScreenType(rawValue: item),
                                    let viewModel = RTRSNavigation.shared.viewModel(for: type){
                                    viewModels.append(viewModel)
                                    let moreViewModel = RTRSMoreViewModel(pages: viewModels)
                                    RTRSNavigation.shared.registerViewModel(viewModel: moreViewModel, for: .more)
                                }
                            }
                        }
                        
                        completionHandler(true)
                    }
                }
                
                for page in pages {
                    if let name = page["name"] as? String, let urlString = page["link"] as? String, let url = URL(string: urlString), let type = page["type"] as? String {
                        
                        if type != "externallink" {
                            let operation = RTRSOperation(url: url, pageName: name, type: type)
                            operation.customCompletion = operationCompletion
                            self.operationQueue.addOperation(operation)
                        } else {
                            // TODO: Get persisted viewModel?
                            operationCompletion(nil)
                        }
                    }
                }
            }
        }
    }
}
