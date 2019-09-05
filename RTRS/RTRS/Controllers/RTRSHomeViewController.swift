//
//  HomeViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSHomeViewController: UITableViewController {

    private var viewModel: RTRSHomeViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = (RTRSNavigation.shared.viewModel(for: .home) as! RTRSHomeViewModel)
        
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor = .black
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RTRSHomeTableViewCell.kReuseId, for: indexPath) as! RTRSHomeTableViewCell
        if let items = self.viewModel.items {
            let homeItem = items[indexPath.row]
            if let text = homeItem.text, let url = homeItem.imageUrl,
                let actionText = homeItem.actionText {
                cell.titleLabel.text = text
                cell.actionLabel.text = "\(actionText) ->"
                cell.homeImageView.pin_setImage(from: url)
            }
        }
        
        return cell
    }
}

class RTRSHomeTableViewCell: UITableViewCell {
    static let kReuseId = "RTRSHomeCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var homeImageView: UIImageView!
    @IBOutlet weak var actionLabel: UILabel!
}
