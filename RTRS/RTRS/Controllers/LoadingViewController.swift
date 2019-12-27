//
//  LoadingViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/11/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import FirebaseDatabase

class LoadingViewController: UIViewController {

    static let storyboardId = "Loading"
    let operationCoordinator = RTRSOperationCoordinator()
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    var loadingMessages = [String]()
    var loadingMessageTimer: Timer?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    static var cachedConfigPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return URL(string: "\(documentsDirectory.absoluteString)RTRSConfig.json")!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let configURLString = Bundle.main.object(forInfoDictionaryKey: "RTRSConfigURL") as? String else {
                // We'll show an error here, but really, it was definitely our fault, lol...
                RTRSErrorHandler.showNetworkError(in: self, completion: nil)
                return
        }
        
        let databaseRef = Database.database().reference().child("token/M0Yez6yEsPnEf1C4qSF4")

        self.navigationController?.navigationBar.isHidden = true
        self.activityIndicator.startAnimating()
        
        databaseRef.observeSingleEvent(of: .value) { (snapshot) in
            if !snapshot.exists() { return }
            
            if let token = snapshot.value as? String {
                let configURLStringWithTemplate = configURLString.replacingOccurrences(of: "{{TOKEN}}", with: token)
                let url = URL(string: configURLStringWithTemplate)
                
                guard let configURL = url else {
                    RTRSErrorHandler.showNetworkError(in: self, completion: nil)
                    return
                }
                
                URLSession.shared.dataTask(with: configURL) { [weak self] (data, response, error) in
                    guard let weakSelf = self else { return }
                    
                    func doStartup(dict: [String: Any]) {
                        guard let weakSelf = self else { return }
                        
                        if let messages = dict["loadingMessages"] as? [String] {
                            weakSelf.loadingMessages = messages
                            weakSelf.loadingMessageTimer = Timer(timeInterval: 5, repeats: true, block: { (timer) in
                                let index = Int.random(in: 0..<weakSelf.loadingMessages.count)
                                let message = weakSelf.loadingMessages[index]
                                DispatchQueue.main.async {
                                    weakSelf.statusLabel.text = message
                                }
                            })
                            
                            if let timer = weakSelf.loadingMessageTimer {
                                RunLoop.main.add(timer, forMode: .default)
                            }
                        }
                        
                        weakSelf.operationCoordinator.beginStartupProcess(dict: dict) { (success) in
                            if success {
                                DispatchQueue.main.async {
                                    weakSelf.activityIndicator.stopAnimating()
                                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "Home")
                                    weakSelf.navigationController?.setViewControllers([vc], animated: true)
                                }
                            } else {
                                RTRSErrorHandler.showNetworkError(in: weakSelf, completion: nil)
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
                    if error != nil {
                        if let config = getBundledConfig() {
                            doStartup(dict: config)
                        } else {
                            RTRSErrorHandler.showNetworkError(in: weakSelf, completion: nil)
                        }
                    } else {
                        if let data = data, let theDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            
                            do {
                                try data.write(to: LoadingViewController.cachedConfigPath)
                            } catch {
                                print("Error saving cached config")
                            }
                            
                            configDict = theDict
                        } else if let data = try? Data(contentsOf: LoadingViewController.cachedConfigPath),
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
                            RTRSErrorHandler.showNetworkError(in: weakSelf, completion: nil)
                        }
                    }
                }.resume()
            }
        }
    }
}
