//
//  LoadingViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/11/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import FirebaseDatabase

@objc class LoadingManager: NSObject {
    
    private override init() {}
    static let shared = LoadingManager()
    let operationCoordinator = RTRSOperationCoordinator()
    var loadingMessages = [String]()
    private let previousLoadUserDefaultsKey = "previousLoadCompleted"
    var previousLoadCompleted: Date? {
        get {
            return UserDefaults.standard.object(forKey: previousLoadUserDefaultsKey) as? Date
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: previousLoadUserDefaultsKey)
        }
    }
    
    @objc dynamic var isLoading = false
    
    static var cachedConfigPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return URL(string: "\(documentsDirectory.absoluteString)RTRSConfig.json")!
    }
    
    func executeStartup(forceReload: Bool) {
        // Nobody is allowed to make requests less than 60 seconds apart
        if let prevLoadFinishTime = LoadingManager.shared.previousLoadCompleted {
            if Date().timeIntervalSince(prevLoadFinishTime) < 60 {
                return
            }
        }
        
        self.isLoading = true
        let databaseRef = Database.database().reference().child("token/M0Yez6yEsPnEf1C4qSF4")

        databaseRef.observeSingleEvent(of: .value) { (snapshot) in
            if !snapshot.exists() { return }
            
            if let token = snapshot.value as? String {
                let url = URL(string: token)
                
                guard let configURL = url else {
                    RTRSErrorHandler.showError(in: nil, type: .network, completion: nil)
                    return
                }
                
                URLSession.shared.dataTask(with: configURL) { [weak self] (data, response, error) in
                    func getBundledConfig() -> [String: Any]? {
                        if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json") {
                            let configUrl = URL(fileURLWithPath: configPath)
                            if let configData = try? Data(contentsOf: configUrl) {
                                return try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any]
                            }
                        }
                        
                        return nil
                    }
                    
                    func getCachedConfig() -> [String: Any]? {
                        if let data = try? Data(contentsOf: LoadingManager.cachedConfigPath),
                                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            return dict
                        }
                        
                        return nil
                    }
                    
                    func doStartup(dict: [String: Any], forceReload: Bool) {
                        guard let weakSelf = self else { return }
                        
                        if let messages = dict["loadingMessages"] as? [String] {
                            weakSelf.loadingMessages = messages
                        }
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .loadingBeganNotification, object: nil)
                        }
                        
                        weakSelf.operationCoordinator.beginStartupProcess(dict: dict, forceReload: forceReload) { (success) in
                            if !success {
                                RTRSErrorHandler.showError(in: nil, type: .network, completion: nil)
                            }
                            
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .loadingFinishedNotification, object: nil)
                                self?.previousLoadCompleted = Date()
                                self?.isLoading = false
                            }
                        }
                    }
                    
                    var isDebug = false
                    #if DEBUG
                    isDebug = true
                    #endif
                    
                    var configDict: [String: Any]?
                    if error != nil || isDebug {
                        if let config = getBundledConfig() {
                            doStartup(dict: config, forceReload: forceReload)
                        } else {
                            RTRSErrorHandler.showError(in: nil, type: .network, completion: nil)
                        }
                    } else {
                        var secondaryForceReload = false
                        if let data = data, let theDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            
                            // Force a reload if the config has changed
                            if let cachedConfig = getCachedConfig() {
                                let nsConfig = cachedConfig as NSDictionary
                                let configsDiffer = !nsConfig.isEqual(to: theDict)
                                secondaryForceReload = configsDiffer
                                if configsDiffer {
                                    do {
                                        try data.write(to: LoadingManager.cachedConfigPath)
                                    } catch {
                                        print("Error saving cached config")
                                    }
                                }
                            }
                            
                            configDict = theDict
                        } else if let config = getCachedConfig() {
                            configDict = config
                        } else {
                            if let config = getBundledConfig() {
                                configDict = config
                            }
                        }
                        
                        if let dict = configDict {
                            doStartup(dict: dict, forceReload: forceReload || secondaryForceReload)
                        } else {
                            RTRSErrorHandler.showError(in: nil, type: .network, completion: nil)
                        }
                    }
                }.resume()
            }
        }
    }
}

extension Notification.Name {
    static let loadingBeganNotification = Notification.Name("LoadingBeganNotification")
    static let loadingFinishedNotification = Notification.Name("LoadingFinishedNotification")
}
