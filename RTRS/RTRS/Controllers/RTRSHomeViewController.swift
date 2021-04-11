//
//  HomeViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

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

        self.viewModel = RTRSNavigation.shared.viewModel(for: .home) as? RTRSHomeViewModel

        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "RickyLogoCutout"), for: .normal)
        button.addTarget(self, action: #selector(openRefreshView), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.frame.size = CGSize(width: 60.0, height: 60.0)
        self.navigationItem.titleView = button
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        showFTUEIfNecessary()
        NotificationCenter.default.addObserver(self, selector: #selector(rotateRefreshButton), name: .loadingBeganNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .homeLoadedNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = AppStyles.backgroundColor
        
        let barAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [RTRSHomeViewController.self])
        barAppearance.barTintColor = AppStyles.backgroundColor
        
        self.navigationController?.navigationBar.tintColor = AppStyles.backgroundColor
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.tableView.reloadData()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.navigationController?.preferredStatusBarStyle ?? .default
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
    }
    
    @objc func loadingFinished() {
        DispatchQueue.main.async {
            self.viewModel = (RTRSNavigation.shared.viewModel(for: .home) as? RTRSHomeViewModel)
            self.tableView.reloadData()
        }
    }
    
    func showFTUEIfNecessary() {
        let firstLaunchFinished = UserDefaults.standard.bool(forKey: firstLaunchFinishedKey)
        let tooltipTitle = "If the logo is spinning, data is being fetched."
        let tooltipMessage = "The app will automatically check for updates on startup. If you ever want to forcibly reload all data, tap the logo."
        let tooltipIdentifier = "FTUE"
        
        if !firstLaunchFinished {
            let alert = UIAlertController(title: "Welcome to the Ricky app!", message: "Please trust the processor as the app loads for the first time.\nWould you like to receive notifications for all Ricky-related updates, including new pods, articles, and events?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { [weak self] (action) in
                guard let self = self, let titleView = self.navigationItem.titleView else { return }
                Utils.showToolTip(in: titleView, title: tooltipTitle, message: tooltipMessage, identifier: tooltipIdentifier, direction: .top)
                UserDefaults.standard.set(true, forKey: self.firstLaunchFinishedKey)
            }))
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                if #available(iOS 10.0, *) {
                    // For iOS 10 display notification (sent via APNS)
                    UNUserNotificationCenter.current().delegate = UIApplication.shared.delegate as! AppDelegate
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(settings)
                }
                
                if let titleView = self.navigationItem.titleView {
                    Utils.showToolTip(in: titleView, title: tooltipTitle, message: tooltipMessage, identifier: tooltipMessage, direction: .top)
                }
                UserDefaults.standard.set(true, forKey: self.firstLaunchFinishedKey)
            }))
            
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func rotateRefreshButton() {
        DispatchQueue.main.async {
            if let titleView = self.navigationItem.titleView {
                if self.refreshButtonShouldRotate {
                    titleView.isUserInteractionEnabled = false
                    let duration: TimeInterval = 1.0
                    UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
                        titleView.transform = titleView.transform.rotated(by: CGFloat(Float.pi))
                    }) { finished in
                        self.rotateRefreshButton()
                    }
                } else {
                    titleView.transform = .identity
                    titleView.isUserInteractionEnabled = true
                    titleView.layer.removeAllAnimations()
                }
            }
        }
    }
    
    @objc private func openRefreshView() {
        guard let titleView = self.navigationItem.titleView else { return }
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "refreshPopover") as! RefreshPopoverViewController
        popController.view.backgroundColor = AppStyles.backgroundColor
        popController.loadingLabel.textColor = AppStyles.foregroundColor
        
        popController.modalPresentationStyle = .popover
        
        popController.popoverPresentationController?.permittedArrowDirections = .any
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = titleView
        popController.popoverPresentationController?.sourceRect = titleView.bounds
        
        self.present(popController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
            let payload = RTRSDeepLinkPayload(baseURL: url as URL, title: title, podURLString: nil, youtubeUrlString: nil)
            RTRSDeepLinkHandler.route(payload: payload, navController: navVC, shouldOpenExternalWebBrowser: homeItem.shouldOpenExternalBrowser)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? RTRSHomeTableViewCell else { return }
        cell.titleLabel.textColor = AppStyles.foregroundColor
        cell.backgroundColor = AppStyles.backgroundColor
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RTRSHomeTableViewCell.kReuseId, for: indexPath) as! RTRSHomeTableViewCell
        if let items = self.viewModel?.items {
            let homeItem = items[indexPath.row]
            if let url = homeItem.imageUrl {
                if let text = homeItem.text {
                    cell.titleLabel.text = text
                    cell.titleLabel.textColor = AppStyles.foregroundColor
                } else {
                    cell.titleLabel.text = ""
                }
                
                cell.homeImageView.af.setImage(withURL: url as URL)
            }
        }
        
        cell.backgroundColor = AppStyles.backgroundColor
        
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.homeImageView.image = nil
    }
}
