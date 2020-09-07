//
//  DebugViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/13/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit
import MessageUI

enum DebugStrings: String {
    case fcmToken
    case deviceInfo
    case osInfo
}

class DebugViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    static let bugReportInfoDict: [DebugStrings: String] = [
        .fcmToken: UserDefaults.standard.string(forKey: DebugStrings.fcmToken.rawValue) ?? "none",
        .deviceInfo: "\(UIDevice.current.localizedModel), iOS \(UIDevice.current.systemVersion)",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(RightDetailCell.self, forCellReuseIdentifier: "debugCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DebugViewController.bugReportInfoDict.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "debugCell", for: indexPath)
        
        if indexPath.section == 0 {
            let keys = Array<DebugStrings>(DebugViewController.bugReportInfoDict.keys)
            let key = keys[indexPath.row]
            cell.textLabel?.text = key.rawValue
            cell.detailTextLabel?.text = DebugViewController.bugReportInfoDict[key]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let keys = Array<DebugStrings>(DebugViewController.bugReportInfoDict.keys)
            let value = keys[indexPath.row]
            UIPasteboard.general.string = value.rawValue
        } else {
            if indexPath.row == 0 {
                if MFMailComposeViewController.canSendMail() {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self
                    mail.setToRecipients(["rtrsapp@gmail.com"])
                    mail.setMessageBody("<p>You're so awesome!</p>", isHTML: true)

                    present(mail, animated: true)
                }
            }
        }
    }
    
}

class RightDetailCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
