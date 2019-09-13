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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
        self.activityIndicator.startAnimating()
        
        if let configPath = Bundle.main.path(forResource: "RTRSConfig", ofType: "json") {
            let configUrl = URL(fileURLWithPath: configPath)
            if let configData = try? Data(contentsOf: configUrl),
                let configDict = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? [String: Any],
                let messages = configDict["loadingMessages"] as? [String] {
                self.loadingMessages = messages
                self.loadingMessageTimer = Timer(timeInterval: 5, repeats: true, block: { [weak self] (timer) in
                    guard let weakSelf = self else { return }
                    let index = Int.random(in: 0..<weakSelf.loadingMessages.count)
                    let message = weakSelf.loadingMessages[index]
                    DispatchQueue.main.async {
                        weakSelf.statusLabel.text = message
                    }
                })
                
                if let timer = self.loadingMessageTimer {
                    RunLoop.main.add(timer, forMode: .default)
                }
            }
        }

        // Do any additional setup after loading the view.
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
        
        operationCoordinator.beginStartupProcess { [weak self] (success) in
            print("\(success)")
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.activityIndicator.stopAnimating()
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "Home")
                weakSelf.navigationController?.setViewControllers([vc], animated: true)
            }
        }
    }
}
