//
//  RefreshPopoverViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 1/11/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit

class RefreshPopoverViewController: UIViewController {

    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var processButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @objc let loadingManager = LoadingManager.shared
    fileprivate var loadingMessageTimer: Timer?
    
    fileprivate var loadingManagerObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingManagerObservation = observe(\.loadingManager.isLoading, changeHandler: { (object, change) in
            if let isLoading = change.newValue {
                DispatchQueue.main.async { [weak self] in
                    if isLoading {
                        self?.loadingDidBegin()
                    } else {
                        self?.loadingFinished()
                    }
                }
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadingDidBegin), name: .loadingBeganNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .loadingFinishedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.loadingManager.isLoading {
            self.loadingDidBegin()
        } else {
            self.loadingFinished()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeArea = self.view.safeAreaInsets
        let height = safeArea.top + 117 + self.processButton.frame.size.height
        let width: CGFloat = 300
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    deinit {
        self.loadingManagerObservation = nil
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func processButtonPressed(_ sender: Any) {
        LoadingManager.shared.executeStartup()
        self.processButton.isEnabled = false
        self.processButton.setTitleColor(.gray, for: .normal)
        self.loadingLabel.text = "PROCESSING......................."
    }
    
    @objc private func loadingDidBegin() {
        let messages = LoadingManager.shared.loadingMessages
        self.loadingMessageTimer = Timer(timeInterval: 5, repeats: true, block: { (timer) in
            let index = Int.random(in: 0..<messages.count)
            let message = messages[index]
            DispatchQueue.main.async { [weak self] in
                self?.loadingLabel.text = message
            }
        })

        if let timer = self.loadingMessageTimer {
            RunLoop.main.add(timer, forMode: .default)
        }
        
        self.loadingLabel.text = "PROCESSING......................."
        self.processButton.isEnabled = false
        self.processButton.setTitleColor(.gray, for: .normal)
    }
    
    @objc private func loadingFinished() {
        self.loadingLabel.text = "Tap to Process data"
        self.processButton.isEnabled = true
        self.processButton.setTitleColor(.systemBlue, for: .normal)
        self.loadingMessageTimer?.invalidate()
    }
}
