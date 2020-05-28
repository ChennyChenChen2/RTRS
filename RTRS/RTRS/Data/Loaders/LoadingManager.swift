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
    @objc var isLoading = false
    
    static var cachedConfigPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return URL(string: "\(documentsDirectory.absoluteString)RTRSConfig.json")!
    }
    
    func executeStartup() {
        guard let configURLString = Bundle.main.object(forInfoDictionaryKey: "RTRSConfigURL") as? String else {
                // We'll show an error here, but really, it was definitely our fault, lol...
                RTRSErrorHandler.showNetworkError(in: nil, completion: nil)
                return
        }
        
        self.isLoading = true
        let databaseRef = Database.database().reference().child("token/M0Yez6yEsPnEf1C4qSF4")

        databaseRef.observeSingleEvent(of: .value) { (snapshot) in
            if !snapshot.exists() { return }
            
            if let token = snapshot.value as? String {
                let configURLStringWithTemplate = configURLString.replacingOccurrences(of: "{{TOKEN}}", with: token)
                let url = URL(string: configURLStringWithTemplate)
                
                guard let configURL = url else {
                    RTRSErrorHandler.showNetworkError(in: nil, completion: nil)
                    return
                }
                
                URLSession.shared.dataTask(with: configURL) { [weak self] (data, response, error) in
                    func doStartup(dict: [String: Any]) {
                        guard let weakSelf = self else { return }
                        
                        if let messages = dict["loadingMessages"] as? [String] {
                            weakSelf.loadingMessages = messages
                        }
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .loadingBeganNotification, object: nil)
                        }
                        
                        weakSelf.operationCoordinator.beginStartupProcess(dict: dict) { (success) in
                            if !success {
                                RTRSErrorHandler.showNetworkError(in: nil, completion: nil)
                            }
                            
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .loadingFinishedNotification, object: nil)
                                self?.isLoading = false
                            }
                        }
                    }
                    
                    func getBundledConfig() -> [String: Any]? {
                        if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json") {
                            let configUrl = URL(fileURLWithPath: configPath)
                            if let configData = try? Data(contentsOf: configUrl) {
                                return try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any]
                            }
                        }
                        
                        return nil
                    }
                    
                    var configDict: [String: Any]?
//                    if error != nil {
                    if true {
                        if let config = getBundledConfig() {
                            doStartup(dict: config)
                        } else {
                            RTRSErrorHandler.showNetworkError(in: nil, completion: nil)
                        }
                    } else {
                        if let data = data, let theDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            do {
                                try data.write(to: LoadingManager.cachedConfigPath)
                            } catch {
                                print("Error saving cached config")
                            }
                            
                            configDict = theDict
                        } else if let data = try? Data(contentsOf: LoadingManager.cachedConfigPath),
                                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            configDict = dict
                        } else {
                            if let config = getBundledConfig() {
                                configDict = config
                            }
                        }
                        
                        if let dict = configDict {
                            doStartup(dict: dict)
                        } else {
                            RTRSErrorHandler.showNetworkError(in: nil, completion: nil)
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
