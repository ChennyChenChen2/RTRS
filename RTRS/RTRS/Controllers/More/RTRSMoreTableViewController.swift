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
    fileprivate let externalBrowserSegueId = "externalweb"
    fileprivate let savedContentSegueId = "Saved"
    var viewModel: RTRSMoreViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = RTRSNavigation.shared.viewModel(for: .more) as? RTRSMoreViewModel
        self.view.backgroundColor = .black
        self.tableView.backgroundColor = .black
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath)
        
        if indexPath.row == 0 {
            
        } else {
            if let vm = self.viewModel, let pages = vm.pages {
                if indexPath.row == pages.count {
                    cell.textLabel?.text = "Saved"
                    cell.imageView?.image = #imageLiteral(resourceName: "Top-Nav-Image")
                } else {
                    let page = pages[indexPath.row]
                    cell.textLabel?.text = page.pageName()
                    cell.imageView?.image = page.pageImage()
                }
            }
        }
        
        cell.textLabel?.textColor = .white

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let page = self.viewModel?.pages?[indexPath.row] {
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
