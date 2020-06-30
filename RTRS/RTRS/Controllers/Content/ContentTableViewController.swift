//
//  AUCornerTableViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class ContentTableViewController: UITableViewController, UISearchBarDelegate, LoggableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    var viewModel: MultiContentViewModel?
    var contentType: RTRSScreenType!
    fileprivate let cellReuseId = "ContentCell"
    fileprivate let articleSegueId = "AUArticleSegue"
    fileprivate let playerId = "PodcastPlayer"
    fileprivate var filteredResults = [SingleContentViewModel?]()
    fileprivate var clearAllButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchBar.delegate = self
        self.navigationController?.navigationBar.isHidden = false
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        determineViewModelType()
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func determineViewModelType() {
        var name: Notification.Name?
        if self.contentType == .au {
            self.navigationItem.title = "AU'S CORNER"
            name = .auLoadedNotificationName
            if let theViewModel = RTRSNavigation.shared.viewModel(for: .au) as? MultiArticleViewModel {
                self.viewModel = theViewModel
            }
        } else if self.contentType == .normalColumn {
            self.navigationItem.title = "SIXERS ADAM: NORMAL COLUMN"
            name = .normalColumnLoadedNotificationName
            if let theViewModel = RTRSNavigation.shared.viewModel(for: .normalColumn) as? MultiArticleViewModel {
                self.viewModel = theViewModel
            }
        } else if self.contentType == .podcasts {
            self.navigationItem.title = "THE POD"
            name = .podLoadedNotificationName
            if let theViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel {
                self.viewModel = theViewModel
            }
        } else if self.contentType == .saved {
            self.navigationItem.title = "SAVED"
            self.clearAllButton = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearAllAction))
            self.navigationItem.rightBarButtonItem = self.clearAllButton
            
            if let theViewModel = RTRSNavigation.shared.viewModel(for: .saved) as? RTRSSavedContentViewModel {
                self.viewModel = theViewModel
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(savedContentUpdated), name: Notification.Name.SavedContentUpdated, object: nil)
        }
        
        if let name = name {
            NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: name, object: nil)
        }
    }
    
    @objc func loadingFinished() {
        determineViewModelType()
        self.tableView.reloadData()
    }
    
    @objc func savedContentUpdated() {
        guard let content = self.viewModel?.content else { return }
        self.clearAllButton?.isEnabled = content.count != 0
        self.filteredResults = content
        self.tableView.reloadData()
    }
    
    @objc func clearAllAction() {
        let alert = UIAlertController(title: "Clear all saved items?", message: nil, preferredStyle: .actionSheet)
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            RTRSPersistentStorage.removeAllSavedContent()
            self.filteredResults = []
            self.clearAllButton?.isEnabled = false
            self.tableView.reloadData()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        savedContentUpdated()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
    }
    
    func viewModelForLogging() -> RTRSViewModel? {
        return self.viewModel is RTRSViewModel ? (self.viewModel as! RTRSViewModel) : nil
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredResults.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! SingleContentCell
        
        guard let viewModel = self.filteredResults[indexPath.row] else { return cell }
        cell.applyViewModel(viewModel: viewModel)

        return cell
    }
    
    /*
        If we're in saved article screen:
            - Only unsave action should be enabled
     
        Any other content screen:
            - If content isn't saved, enable save. Otherwise, enable unsasve.
     
        Save action:
            - Trigger RTRSPersistentStorage.save method. reloadData. If cell is swiped again, unsave should be shown.
     
        Unsave action:
            - If on regular content screen: same as save action, but with unsave.
     
     */
    override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let saveAction = UITableViewRowAction(style: .normal, title: "Save") { [weak self] (action, path) in
            guard let weakSelf = self else { return }
            if let vm = weakSelf.viewModel?.content[path.row] {
                RTRSPersistentStorage.saveContent(vm)
            }
            
            weakSelf.tableView.reloadData()
        }
        
        saveAction.backgroundColor = UIColor(displayP3Red: 54.0/255.0, green: 200.0/255.0, blue: 54.0/255.0, alpha: 1.0)
        
        let unsaveAction = UITableViewRowAction(style: .destructive, title: "Unsave") { [weak self] (action, path) in
            guard let weakSelf = self else { return }
            if let vm = weakSelf.viewModel?.content[path.row] {
                RTRSPersistentStorage.unsaveContent(vm)
            }
            
            if let content = weakSelf.viewModel?.content, weakSelf.contentType == .saved {
                weakSelf.filteredResults = content
            }
            
            weakSelf.tableView.reloadData()
        }
        
        if self.contentType == .saved {
            return [unsaveAction]
        } else {
            if let vm = self.viewModel?.content[editActionsForRowAt.row] {
                if RTRSPersistentStorage.contentIsAlreadySaved(vm: vm) {
                    return [unsaveAction]
                } else {
                    return [saveAction]
                }
            }
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = self.viewModel?.content[indexPath.row] else { return }
        
        if viewModel is SingleArticleViewModel {
            self.performSegue(withIdentifier: self.articleSegueId, sender: indexPath)
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? SingleContentCell, let title = cell.contentTitleLabel.text {

                if let viewModel = self.viewModel?.content.first(where: { (vm) -> Bool in
                    guard let vm = vm else { return false }
                    return vm.title == title
                }) as? RTRSSinglePodViewModel {
                    var vc: PodcastPlayerViewController!
                    if let theVC = PodcastManager.shared.currentPodVC, let currentPodTitle = PodcastManager.shared.title, title == currentPodTitle {
                        vc = theVC
                    } else {
                        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                        vc = (storyboard.instantiateViewController(withIdentifier: self.playerId) as! PodcastPlayerViewController)
                        
                        vc.viewModel = viewModel
                        PodcastManager.shared.currentPodVC = vc
                    }
                    
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = sender as? IndexPath else { return }
        let vc = segue.destination as! AUCornerArticleViewController
        if indexPath.row < self.filteredResults.count {
            vc.viewModel = self.filteredResults[indexPath.row] as? SingleArticleViewModel
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
            guard let viewModel = viewModel else { return false }
            if let title = viewModel.title, title.lowercased().contains(searchText.lowercased()) {
                return true
            } else if let description = viewModel.contentDescription?.lowercased(), description.contains(searchText.lowercased()) {
                return true
            } else if let dateString = viewModel.dateString?.lowercased(), dateString.contains(searchText.lowercased()) {
                return true
            }
            
            return false
        }
        self.tableView.reloadData()
    }
}
