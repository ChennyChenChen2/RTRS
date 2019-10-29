//
//  LoadingViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/11/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

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
        
        guard let configURLString = Bundle.main.object(forInfoDictionaryKey: "RTRSConfigURL") as? String,
            let configURL = URL(string: configURLString) else { return }
        
        self.navigationController?.navigationBar.isHidden = true
        self.activityIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: configURL) { [weak self] (data, response, error) in
            guard let data = data, let weakSelf = self else { return }
            
            var dict: [String: Any]?
            if let configDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let messages = configDict["loadingMessages"] as? [String] {
//                dict = configDict
                
                do {
                    try data.write(to: LoadingViewController.cachedConfigPath)
                } catch {
                    print("Error saving cached config")
                }
                
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

            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            let request = URLRequest(url: URL(string: "https://www.rightstorickysanchez.com/?format=json-pretty")!)
            let task = urlSession.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                if let data = data,
                    let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                    let collectionDict = dict["collection"] as? [String: Any], let updated = collectionDict["updatedOn"] as? Int {
                    
                    let lastUpdate = UserDefaults.standard.integer(forKey: RTRSUserDefaultsKeys.lastUpdated)
                    if updated > lastUpdate {
                        UserDefaults.standard.set(updated, forKey: RTRSUserDefaultsKeys.lastUpdated)
                    }
                }
            }
            
            task.resume()
            
            weakSelf.operationCoordinator.beginStartupProcess(dict: dict) { (success) in
                DispatchQueue.main.async {
                    weakSelf.activityIndicator.stopAnimating()
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "Home")
                    weakSelf.navigationController?.setViewControllers([vc], animated: true)
                }
            }
        }.resume()
    }
}
