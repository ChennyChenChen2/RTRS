//
//  AUCornerTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class AUCornerTableViewController: UITableViewController {

    var viewModel: AUCornerMultiArticleViewModel!
    fileprivate let cellReuseId = "AUCell"
    fileprivate let articleSegueId = "AUArticleSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isHidden = false
        self.viewModel = RTRSNavigation.shared.viewModel(for: .au) as? AUCornerMultiArticleViewModel
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.articles.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! AUCornerTableViewCell
        
        let viewModel = self.viewModel.articles[indexPath.row]
        cell.applyViewModel(viewModel: viewModel)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: self.articleSegueId, sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = sender as? IndexPath else { return }
        let vc = segue.destination as! AUCornerArticleViewController
        if indexPath.row < self.viewModel.articles.count {
            vc.viewModel = self.viewModel.articles[indexPath.row]
        }
    }
}
