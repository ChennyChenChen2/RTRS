//
//  AUCornerTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class ContentTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    var viewModel: MultiContentViewModel?
    var contentType: RTRSScreenType!
    fileprivate let cellReuseId = "ContentCell"
    fileprivate let articleSegueId = "AUArticleSegue"
    fileprivate let playerId = "PodcastPlayer"
    fileprivate var filteredResults = [SingleContentViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchBar.delegate = self
        self.navigationController?.navigationBar.isHidden = false
        
        if self.contentType == .au, let theViewModel = RTRSNavigation.shared.viewModel(for: .au) as? AUCornerMultiArticleViewModel {
            self.viewModel = theViewModel
        } else if self.contentType == .podcasts, let theViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel {
            self.viewModel = theViewModel
        }
        
        if let content = self.viewModel?.content {
            self.filteredResults = content
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredResults.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! SingleContentCell
        
        let viewModel = self.filteredResults[indexPath.row]
        cell.applyViewModel(viewModel: viewModel)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.contentType == .au {
            self.performSegue(withIdentifier: self.articleSegueId, sender: indexPath)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: self.playerId)
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = sender as? IndexPath else { return }
        let vc = segue.destination as! AUCornerArticleViewController
        if indexPath.row < self.filteredResults.count {
            vc.viewModel = self.filteredResults[indexPath.row] as? AUCornerSingleArticleViewModel
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text {
            filter(searchText: searchText)
        }
    }
    
    // MARK - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText: searchText)
    }
    
    fileprivate func filter(searchText: String) {
        guard let articles = self.viewModel?.content else { return }
        
        if searchText == "" {
            self.filteredResults = articles
            self.tableView.reloadData()
            return
        }
        
        self.filteredResults = articles.filter { (viewModel) -> Bool in
            
            if let title = viewModel.title, title.contains(searchText) {
                return true
            } else if let description = viewModel.contentDescription, description.contains(searchText) {
                return true
            } else if let dateString = viewModel.dateString, dateString.contains(searchText) {
                return true
            }
            
            return false
        }
        self.tableView.reloadData()
    }
}
