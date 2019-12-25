//
//  HomeViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSHomeViewController: UITableViewController, LoggableViewController {
    private var viewModel: RTRSHomeViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = (RTRSNavigation.shared.viewModel(for: .home) as? RTRSHomeViewModel)
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.navigationItem.customizeNavBarForHome()
        
        let titleImageView = UIImageView(image: #imageLiteral(resourceName: "Top-Nav-Image"))
        titleImageView.contentMode = .scaleAspectFit
        titleImageView.frame.size = CGSize(width: 50.0, height: 50.0)
        self.navigationItem.titleView = titleImageView
        self.view.backgroundColor = .black
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setNeedsLayout()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
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
                cell.actionLabel.text = "\(actionText) ->"
                cell.homeImageView.pin_setImage(from: url)
            }
        }
        
        return cell
    }
    
    func viewModelForLogging() -> RTRSViewModel? {
        return self.viewModel
    }
}

class RTRSHomeTableViewCell: UITableViewCell {
    static let kReuseId = "RTRSHomeCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var homeImageView: UIImageView!
    @IBOutlet weak var actionLabel: UILabel!
}
