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
    
    func beginStartupProcess(completionHandler: @escaping (Bool) -> ()) {
        
        if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json"),
            let configUrl = URL(string: configPath),
            let configData = try? Data(contentsOf: configUrl),
            let configDict = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any],
            let pages = configDict["pages"] as? [[String: Any]] {
                UserDefaults.standard.set(configDict, forKey: RTRSUserDefaultsKeys.configStorage)
            
                for page in pages {
                    if let name = page["name"] as? String, let urlString = page["link"] as? String, let url = URL(string: urlString) {
                        let operation = RTRSOperation(url: url, pageName: name)
                        operationQueue.addOperation(operation)
                    }
                }
        }
        
        
    }
    
    
}
