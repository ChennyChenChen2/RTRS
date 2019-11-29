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
            
            func doStartup(dict: [String: Any]?) {
                guard let weakSelf = self else { return }
                weakSelf.operationCoordinator.beginStartupProcess(dict: dict) { (success) in
                    if success {
                        DispatchQueue.main.async {
                            weakSelf.activityIndicator.stopAnimating()
                            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "Home")
                            weakSelf.navigationController?.setViewControllers([vc], animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Something went wrong. You hate to see it.", message: "Maybe your internet is as bad as AU's. Please try again later, or contact Kornblau if you suspect someone is sabotaging you.", preferredStyle: .alert)
                            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(action)
                            weakSelf.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            
            if error != nil {
                doStartup(dict: nil)
            }
            
            guard let data = data, let weakSelf = self else { return }
            
            var dict: [String: Any]? // DO NOT DELETE: currently unused bc trying to test locally
            if let configDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let messages = configDict["loadingMessages"] as? [String] {
//                dict = configDict // DO NOT DELETE for same reason above
                
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
            
            doStartup(dict: dict)
        }.resume()
    }
}
