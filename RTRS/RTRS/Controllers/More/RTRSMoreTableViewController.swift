//
//  RTRSMoreTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSMoreTableViewController: UITableViewController {

    fileprivate let cellReuseId = "MoreCell"
    fileprivate let externalBrowserSegueId = "extternalweb"
    var viewModel: RTRSMoreViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
        self.view.backgroundColor = .black
        self.tableView.backgroundColor = .black
        self.navigationController?.navigationBar.backgroundColor = .black
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModel?.pages?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
        if let page = self.viewModel?.pages?[indexPath.row] {
            cell.textLabel?.text = page.pageName()
            cell.textLabel?.textColor = .white
            cell.imageView?.image = page.pageImage()
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let page = self.viewModel?.pages?[indexPath.row] {
            if let _ = page.pageUrl() {
                self.performSegue(withIdentifier: self.externalBrowserSegueId, sender: page)
            } else {
             self.performSegue(withIdentifier: page.pageName(), sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let page = sender as? RTRSViewModel else { return }
        if let id = segue.identifier, id == self.externalBrowserSegueId,
            let pageUrl = page.pageUrl(), let vc = segue.destination as? RTRSExternalWebViewController {
            vc.url = pageUrl
            vc.name = page.pageName()
        }
    }
}
