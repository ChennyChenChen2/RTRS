//
//  RTRSMoreTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSMoreTableViewController: UITableViewController, NotificationCellDelegate {

    fileprivate let cellReuseId = "MoreCell"
    fileprivate let notificationCellReuseId = "NotificationCell"
    fileprivate let externalBrowserSegueId = "externalweb"
    fileprivate let savedContentSegueId = "Saved"
    var viewModel: RTRSMoreViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
        self.view.backgroundColor = .black
        self.tableView.backgroundColor = .black
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backgroundColor = .black
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .moreLoadedNotificationName, object: nil)
    }
    
    @objc private func loadingFinished() {
        DispatchQueue.main.async {
            self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backgroundColor = .black
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (viewModel?.pages?.count ?? 0) + 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if indexPath.row == 0 {
            let noteCell = tableView.dequeueReusableCell(withIdentifier: self.notificationCellReuseId, for: indexPath) as! NotificationsTableViewCell
            noteCell.delegate = self
            noteCell.cellImageView.image = UIImage(imageLiteralResourceName: "Notifications")
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                DispatchQueue.main.async {
                    noteCell.notificationSwitch.isOn = settings.authorizationStatus == .authorized
                }
            }
            
            cell = noteCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
            
            if let vm = self.viewModel, let pages = vm.pages {
                if indexPath.row == pages.count + 1 {
                    cell.textLabel?.text = "Saved"
                    cell.imageView?.image = #imageLiteral(resourceName: "Top-Nav-Image")
                } else {
                    let page = pages[indexPath.row - 1]
                    cell.textLabel?.text = page.pageName()
                    cell.imageView?.image = page.pageImage()
                }
            }
        }
        
        cell.textLabel?.textColor = .white

        return cell
    }
    
//    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//
//    }
    
    func switchValueChanged(_ sender: UISwitch) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            if settings.authorizationStatus == .denied {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                
                let alert = UIAlertController(title: "Notifications have been disabled for the Ricky app.", message: "If you would like to enable notifications, please navigate to the settings app to enable them.", preferredStyle: UIAlertController.Style.alert)
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
                    UIUserNotificationSettings(types: [.alert], categories: nil)
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
            let page = pages[indexPath.row - 1]
            if let _ = page.pageUrl() {
                self.performSegue(withIdentifier: self.externalBrowserSegueId, sender: page)
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
            }
        }
    }
}

protocol NotificationCellDelegate: UIViewController {
    func switchValueChanged(_ sender: UISwitch)
}

class NotificationsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var cellImageView: UIImageView!
    weak var delegate: NotificationCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        NotificationCenter.default.removeObserver(self)
        cellImageView.image = nil
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: Notification.Name.WillEnterForeground, object: nil)
    }
    
    @objc func willEnterForeground() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.async { [weak self] in
                self?.notificationSwitch.isOn = settings.authorizationStatus == .authorized
            }
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        self.delegate?.switchValueChanged(sender)
    }
    
}
