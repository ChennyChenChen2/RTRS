//
//  DebugViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/13/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit

enum DebugStrings: String {
    case fcmToken
    case deviceInfo
    case osInfo
    case sendBugReport
    case crash
}

class DebugViewController: UITableViewController {
    
    let infoDict: [DebugStrings: String] = [
        .fcmToken: UserDefaults.standard.string(forKey: DebugStrings.fcmToken.rawValue) ?? "none",
        .deviceInfo: UIDevice.current.localizedModel,
        .osInfo: UIDevice.current.systemVersion
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "debugCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return infoDict.count
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "debugCell", for: indexPath)
        
        if indexPath.section == 0 {
            let keys = Array<DebugStrings>(infoDict.keys)
            let key = keys[indexPath.row]
            cell.textLabel?.text = key.rawValue
            cell.detailTextLabel?.text = infoDict[key]
        } else {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Submit bug report"
            } else {
                cell.textLabel?.text = "CRASH"
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let keys = Array<DebugStrings>(infoDict.keys)
            
            
        } else {
            
        }
    }
    
}
