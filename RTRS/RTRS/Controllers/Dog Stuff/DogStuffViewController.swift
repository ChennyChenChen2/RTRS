//
//  DogStuffViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/6/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import Foundation
import UIKit

class DogStuffViewController: UITableViewController {
    
    private let dogStuffPages: [RTRSScreenType] = [.processPups, .goodDogClub]
    private var dogStuffViewModels: [RTRSViewModel] {
        var result = [RTRSViewModel]()
        for page in dogStuffPages {
            if let viewModel = RTRSNavigation.shared.viewModel(for: page) {
                result.append(viewModel)
            }
        }
        return result
    }
    
    private let gallerySegueId = "GalleryVC"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.styleForDarkMode()
        self.navigationItem.title = "Dog Stuff"
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .processPupsLoadedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .goodDogClubLoadedNotificationName, object: nil)
    }
    
    private func styleForDarkMode() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.backgroundColor = AppStyles.backgroundColor
        
        self.tableView.backgroundColor = AppStyles.backgroundColor
    }
    
    @objc private func loadingFinished() {
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dogStuffViewModels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DogStuffCell") else { return UITableViewCell() }
        let vm = dogStuffViewModels[indexPath.row]
        cell.contentView.backgroundColor = AppStyles.backgroundColor
        cell.textLabel?.textColor = AppStyles.foregroundColor
        cell.textLabel?.text = vm.pageName()
        cell.imageView?.image = vm.pageImage()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vm = dogStuffViewModels[indexPath.row]
        self.performSegue(withIdentifier: gallerySegueId, sender: vm.pageName())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GalleryViewController, let pageNameString = sender as? String, let page = RTRSScreenType(rawValue: pageNameString) {
            vc.contentType = page
        }
    }
}
