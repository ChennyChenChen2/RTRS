//
//  AppSettingsViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/1/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit
import MessageUI

enum AppSettings: String, CaseIterable {
    static let darkModeUserDefaultsKey = "darkModeEnabled"
    
    case DarkMode = "Dark Mode"
    case TextSize = "Text Size"
    case ReportABug = "Report A Bug"
}

/*
 Text size
 Dark mode/light mode
 Report a Bug
 */

class AppSettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate, RightSwitchCellDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleForDarkMode()
        NotificationCenter.default.addObserver(self, selector: #selector(styleForDarkMode), name: .darkModeUpdated, object: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return AppStyles.darkModeEnabled ? .lightContent : .default
    }
    
    @objc private func styleForDarkMode() {
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.backgroundColor = AppStyles.backgroundColor
        
        self.view.backgroundColor = AppStyles.backgroundColor
        self.tableView.backgroundColor = AppStyles.backgroundColor
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppSettings.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = AppSettings.allCases[indexPath.row]
        
        if setting == AppSettings.DarkMode {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DarkModeCell", for: indexPath) as! RightSwitchTableViewCell
            cell.delegate = self
            cell.titleLabel.textColor = AppStyles.foregroundColor
            cell.contentView.backgroundColor = AppStyles.backgroundColor
            cell.notificationSwitch.isOn = UserDefaults.standard.bool(forKey: AppSettings.darkModeUserDefaultsKey)
            cell.notificationSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppSettingsCell", for: indexPath)
            cell.contentView.backgroundColor = AppStyles.backgroundColor
            cell.textLabel?.textColor = AppStyles.foregroundColor
            cell.textLabel?.text = setting.rawValue
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let setting = AppSettings.allCases[indexPath.row]
        
        if setting == .ReportABug {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["rtrsapp@gmail.com"])
                
                var body = ""
                for (key, value) in DebugViewController.bugReportInfoDict {
                    body += "<p>\(key): \(value)</p>"
                }
                
                body += "***** Please include your bug description below this line. Please include instructions to reproduce the issue if possible. *****"
                
                mail.setMessageBody(body, isHTML: true)

                present(mail, animated: true)
            }
        } else if setting == .TextSize {
            Font.presentTextSizeSheet(in: self, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: AppSettings.darkModeUserDefaultsKey)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: .darkModeUpdated, object: nil)
    }
}

extension Notification.Name {
    static let darkModeUpdated = Notification.Name("DarkModeUpdated")
}
