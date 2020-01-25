//
//  HomeViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import MKToolTip

class RTRSHomeViewController: UITableViewController, LoggableViewController, UIPopoverPresentationControllerDelegate {
    private let firstLaunchFinishedKey = "kRTRSFirstLaunchFinishedKey"
    private var viewModel: RTRSHomeViewModel?
    var refreshButtonShouldRotate: Bool {
        get {
            return LoadingManager.shared.isLoading
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = (RTRSNavigation.shared.viewModel(for: .home) as? RTRSHomeViewModel)
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.navigationItem.customizeNavBarForHome()

        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "RickyLogoCutout"), for: .normal)
        button.addTarget(self, action: #selector(openRefreshView), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.frame.size = CGSize(width: 50.0, height: 50.0)
        self.navigationItem.titleView = button
        self.view.backgroundColor = .black
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        showFTUEIfNecessary()
        NotificationCenter.default.addObserver(self, selector: #selector(rotateRefreshButton), name: .LoadingBeganNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .homeLoadedNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setNeedsLayout()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
        rotateRefreshButton()
    }
    
    @objc func loadingFinished() {
        self.viewModel = (RTRSNavigation.shared.viewModel(for: .home) as? RTRSHomeViewModel)
        self.tableView.reloadData()
    }
    
    func showFTUEIfNecessary() {
        let firstLaunchFinished = UserDefaults.standard.bool(forKey: firstLaunchFinishedKey)
        if !firstLaunchFinished {
            UserDefaults.standard.set(true, forKey: firstLaunchFinishedKey)
            let alert = UIAlertController(title: "Welcome to the Ricky app!", message: "Please trust the processor as the app loads for the first time.\nWould you like to receive notifications for all Ricky-related updates, including new pods, articles, and events?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                if #available(iOS 10.0, *) {
                    // For iOS 10 display notification (sent via APNS)
                    UNUserNotificationCenter.current().delegate = UIApplication.shared.delegate as! AppDelegate
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(settings)
                }
            }))
            
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: {
                    let gradientColor = UIColor.black
                    let gradientColor2 = UIColor.darkGray
                    let preference = ToolTipPreferences()
                    preference.drawing.bubble.gradientColors = [gradientColor, gradientColor2]
                    preference.drawing.arrow.tipCornerRadius = 0
                    preference.drawing.title.color = .white
                    preference.drawing.message.color = .white
                    self.navigationItem.titleView?.showToolTip(identifier: "FTUE", title: "Tap here to fetch the latest data.", message: "The app will automatically check on startup.", button: nil, arrowPosition: .top, preferences: preference, delegate: nil)
                })
            }
        }
    }
    
    @objc private func rotateRefreshButton() {
        if let titleView = self.navigationItem.titleView {
            
            if self.refreshButtonShouldRotate {
                titleView.isUserInteractionEnabled = false
                let duration: TimeInterval = 5.0
                UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: { [weak self] in
                    self?.navigationItem.titleView?.transform = titleView.transform.rotated(by: CGFloat(Float.pi))
                }) { [weak self] finished in
                    self?.rotateRefreshButton()
                }
            } else {
                titleView.transform = .identity
                titleView.isUserInteractionEnabled = true
                titleView.layer.removeAllAnimations()
            }
        }
    }
    
    @objc private func openRefreshView() {
        guard let titleView = self.navigationItem.titleView else { return }
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "refreshPopover") as! RefreshPopoverViewController
        popController.modalPresentationStyle = .popover
        
        // set up the popover presentation controller
        popController.popoverPresentationController?.permittedArrowDirections = .any
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = titleView
        popController.popoverPresentationController?.sourceRect = titleView.bounds
        
        // present the popover
        self.present(popController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModelItems = self.viewModel?.items else { return }
        
        let homeItem = viewModelItems[indexPath.row]
        if let url = homeItem.actionUrl, let title = homeItem.text, let navVC = self.navigationController as? RTRSNavigationController {
            let payload = RTRSDeepLinkPayload(baseURL: url, title: title)
            RTRSDeepLinkHandler.route(payload: payload, navController: navVC)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RTRSHomeTableViewCell.kReuseId, for: indexPath) as! RTRSHomeTableViewCell
        if let items = self.viewModel?.items {
            let homeItem = items[indexPath.row]
            if let text = homeItem.text, let url = homeItem.imageUrl,
                let actionText = homeItem.actionText {
                cell.titleLabel.text = text
                cell.actionLabel.text = "\(actionText)"
                cell.homeImageView.pin_setImage(from: url)
            }
        }
        
        return cell
    }
    
    func viewModelForLogging() -> RTRSViewModel? {
        return self.viewModel
    }
    
    // MARK-- UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
     
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension UINavigationBar {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let items = self.items {
            for item in items {
                if let button = item.titleView as? UIButton {
                    for touch in touches {
                        let touchLocation = touch.location(in: button)
                        if ((button.layer.presentation()?.hitTest(touchLocation)) != nil) {
                            button.sendActions(for: .touchUpInside)
                            return
                        }
                    }
                }
            }
        }
    }
}

class RTRSHomeTableViewCell: UITableViewCell {
    static let kReuseId = "RTRSHomeCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var homeImageView: UIImageView!
    @IBOutlet weak var actionLabel: UILabel!
}
