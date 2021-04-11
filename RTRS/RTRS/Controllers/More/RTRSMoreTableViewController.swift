//
//  RTRSMoreTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import MessageUI

#if DEBUG
import FLEX
#endif

class RTRSMoreTableViewController: UITableViewController, RightSwitchCellDelegate, LoggableViewController {
    fileprivate let cellReuseId = "MoreCell"
    fileprivate let notificationCellReuseId = "NotificationCell"
    fileprivate let externalBrowserSegueId = "externalweb"
    fileprivate let savedContentSegueId = "Saved"
    fileprivate let appSettingsSegueId = "AppSettings"
    fileprivate let gallerySegueId = "Gallery"
    fileprivate let dogStuffSegueId = "DogStuff"
    
    var viewModel: RTRSMoreViewModel?
    func viewModelForLogging() -> RTRSViewModel? {
        return self.viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(showDebug))
        gesture.numberOfTapsRequired = 5
        self.view.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .moreLoadedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(styleForDarkMode), name: .darkModeUpdated, object: nil)
    }
    
    @objc private func loadingFinished() {
        DispatchQueue.main.async {
            self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
            self.tableView.reloadData()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return AppStyles.darkModeEnabled ? .lightContent : .default
    }
    
    @objc private func showDebug() {
        let vc = DebugViewController(style: .grouped)
        DispatchQueue.main.async {
            self.navigationController?.present(vc, animated: true, completion: nil)
        }
        
        #if DEBUG
        FLEXManager.shared()?.showExplorer()
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleForDarkMode()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
    }
    
    @objc private func styleForDarkMode() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.backgroundColor = AppStyles.backgroundColor
        
        self.tableView.backgroundColor = AppStyles.backgroundColor
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (viewModel?.pages?.count ?? 0) + 4 // 4 = Notifications, app settings, pet stuff, Mail
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if indexPath.row == 0 {
            // First row == notifications
            let noteCell = tableView.dequeueReusableCell(withIdentifier: self.notificationCellReuseId, for: indexPath) as! RightSwitchTableViewCell
            noteCell.delegate = self
            noteCell.titleLabel.textColor = AppStyles.foregroundColor
            noteCell.cellImageView?.image = UIImage(imageLiteralResourceName: "Notifications")
            noteCell.onForeground = { (cell) in
                UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                    DispatchQueue.main.async {
                        cell.notificationSwitch.isOn = settings.authorizationStatus == .authorized
                    }
                }
            }
            
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                DispatchQueue.main.async {
                    noteCell.notificationSwitch.isOn = settings.authorizationStatus == .authorized
                }
            }
            
            cell = noteCell
        } else if indexPath.row == 1 {
            // Second row = pet stuff
            cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
            cell.textLabel?.text = "Pet Stuff"
            cell.imageView?.image = AppStyles.dogStuffIcon
        } else if indexPath.row == self.tableView.numberOfRows(inSection: 0) - 2 {
            cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
            cell.textLabel?.text = "E-mail The Ricky"
            cell.imageView?.image = AppStyles.mailIcon
        } else if indexPath.row == self.tableView.numberOfRows(inSection: 0) - 1 {
            // Last row = app settings
            cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
            cell.textLabel?.text = "App Settings"
            cell.imageView?.image = AppStyles.settingsIcon
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
            
            if let vm = self.viewModel, let pages = vm.pages {
                if indexPath.row == pages.count + 2 {
                    cell.textLabel?.text = "Saved"
                    cell.imageView?.image = #imageLiteral(resourceName: "Top-Nav-Image")
                } else {
                    let page = pages[indexPath.row - 2]
                    cell.textLabel?.text = page.pageName()
                    cell.imageView?.image = page.pageImage()
                }
            }
        }
        
        cell.contentView.backgroundColor = AppStyles.backgroundColor
        cell.textLabel?.textColor = AppStyles.foregroundColor

        return cell
    }
    
    func switchValueChanged(_ sender: UISwitch) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            if settings.authorizationStatus == .denied {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                
                let alert = UIAlertController(title: "Notifications have been disabled.", message: "If you would like to enable notifications, please navigate to the settings app to enable them.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    sender.isOn = false
                }))
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }))
                
                DispatchQueue.main.async {
                    self.present(alert, animated: false, completion: nil)
                }
            } else if settings.authorizationStatus == .notDetermined {
                if #available(iOS 10.0, *) {
                    // For iOS 10 display notification (sent via APNS)
                    DispatchQueue.main.async {
                        UNUserNotificationCenter.current().delegate = UIApplication.shared.delegate as! AppDelegate
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    let settings: UIUserNotificationSettings =
                        UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
                    DispatchQueue.main.async {
                        UIApplication.shared.registerUserNotificationSettings(settings)
                    }
                }
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                DispatchQueue.main.async {
                    UIApplication.shared.unregisterForRemoteNotifications()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let pages = self.viewModel?.pages, indexPath.row - 1 >= 0 {
            if indexPath.row == self.tableView.numberOfRows(inSection: 0) - 1 {
                self.performSegue(withIdentifier: self.appSettingsSegueId, sender: nil)
                return
            } else if indexPath.row == 1 {
                self.performSegue(withIdentifier: dogStuffSegueId, sender: nil)
                return
            } else if indexPath.row == tableView.numberOfRows(inSection: 0) - 2 {
                // Mail
                if MFMailComposeViewController.canSendMail() {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self
                    mail.setToRecipients(["rightstorickysanchez@gmail.com"])
                    present(mail, animated: true)
                } else {
                    RTRSErrorHandler.showError(in: self, type: .mailNotEnabled, completion: nil)
                }
                
                return
            }
            
            guard indexPath.row - 2 >= 0 else {
                print("INVALID INDEX PATH: \(indexPath)")
                return
            }
            
            let page = pages[indexPath.row - 2]
            if let _ = page.pageUrl() {
                self.performSegue(withIdentifier: self.externalBrowserSegueId, sender: page)
            } else if let type = RTRSScreenType(rawValue: page.pageName()), type == .processPups || type == .abbie {
                self.performSegue(withIdentifier: gallerySegueId, sender: page)
            } else {
                self.performSegue(withIdentifier: page.pageName(), sender: page)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let page = sender as? RTRSViewModel else { return }
        if let id = segue.identifier {
            if id == self.externalBrowserSegueId,
            let pageUrl = page.pageUrl(), let vc = segue.destination as? RTRSExternalWebViewController {
                vc.url = pageUrl
                vc.name = page.pageName()
            } else if id == self.savedContentSegueId, let vc = segue.destination as? ContentTableViewController {
                vc.contentType = .saved
            } else if let vc = segue.destination as? GalleryViewController {
                if let type = RTRSScreenType(rawValue: page.pageName()) {
                    vc.contentType = type
                }
            }
        }
    }
}

extension RTRSMoreTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}

protocol RightSwitchCellDelegate: UIViewController {
    func switchValueChanged(_ sender: UISwitch)
}

class RightSwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var cellImageView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel!
    weak var delegate: RightSwitchCellDelegate?
    var onForeground: ((RightSwitchTableViewCell)->())?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        NotificationCenter.default.removeObserver(self)
        cellImageView?.image = nil
        onForeground = nil
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: Notification.Name.WillEnterForeground, object: nil)
    }
    
    @objc func willEnterForeground() {
        onForeground?(self)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        self.delegate?.switchValueChanged(sender)
    }
}
