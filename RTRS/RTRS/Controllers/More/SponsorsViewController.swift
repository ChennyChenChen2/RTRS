//
//  SponsorsViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/7/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import Foundation
import UIKit

class SponsorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    let viewModel = RTRSNavigation.shared.viewModel(for: .sponsors) as? RTRSSponsorsViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        
        if let description = self.viewModel?.sponsorDescription {
            self.descriptionTextView.text = description
        }
        
        self.navigationItem.title = "Sponsors"
        self.styleForDarkMode()
    }
    
    private func styleForDarkMode() {
        self.view.backgroundColor = AppStyles.backgroundColor
        
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.view.backgroundColor = AppStyles.backgroundColor
        
        self.descriptionTextView.backgroundColor = AppStyles.backgroundColor
        self.descriptionTextView.textColor = AppStyles.foregroundColor
        self.tableView.backgroundColor = AppStyles.backgroundColor
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Tap to be redirected to sponsor's site:"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.backgroundColor = AppStyles.backgroundColor
            view.textLabel?.textColor = AppStyles.foregroundColor
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.sponsors.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sponsor = viewModel?.sponsors[indexPath.row] else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SponsorCell", for: indexPath)
        cell.selectionStyle = .gray
        
        cell.contentView.backgroundColor = AppStyles.backgroundColor
        cell.textLabel?.text = sponsor.name
        cell.textLabel?.textColor = AppStyles.foregroundColor
        
        cell.detailTextLabel?.text = sponsor.promo
        cell.detailTextLabel?.textColor = AppStyles.foregroundColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sponsor = viewModel?.sponsors[indexPath.row],
            let link = sponsor.link,
            let name = sponsor.name else { return }
        RTRSExternalWebViewController.openExternalWebBrowser(self, url: link, name: name)
    }
}
