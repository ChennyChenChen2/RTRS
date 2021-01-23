//
//  ContentViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import CoreGraphics

class ContentViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let mocSegueId = "The Good O'Connor (Mike)"
    fileprivate let auCornerSegueId = "If Not, Pick Will Convey As Two Second-Rounders"
    fileprivate let podSegueId = "The Pod"
    fileprivate let normalColumnSegueId = "Sixers Adam Normal Column"
    
    private let contentPageTypes: [RTRSScreenType] = [.podcasts, .au, .normalColumn, .moc]
    
    private let contentPageImageMap: [RTRSScreenType: UIImage] = [
        .podcasts: #imageLiteral(resourceName: "Pod"),
        .au: #imageLiteral(resourceName: "AU"),
        .normalColumn: #imageLiteral(resourceName: "NormalColumn"),
        .moc: #imageLiteral(resourceName: "MOC")
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleForDarkMode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        self.navigationItem.title = "CONTENT"
        
        NotificationCenter.default.addObserver(self, selector: #selector(styleForDarkMode), name: .darkModeUpdated, object: nil)
    }
    
    @objc private func styleForDarkMode() {
        self.view.backgroundColor = AppStyles.backgroundColor
        self.collectionView.backgroundColor = AppStyles.backgroundColor
        
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contentPageTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let page = self.contentPageTypes[indexPath.row]
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentCell", for: indexPath) as? ContentCollectionViewCell,
            let image = self.contentPageImageMap[page] else { return UICollectionViewCell() }
        
        
        cell.titleLabel.text = page.rawValue.uppercased()
        cell.titleLabel.textColor = AppStyles.foregroundColor
        
        cell.imageView.image = image
        cell.imageView.tintColor = AppStyles.foregroundColor
        
        cell.contentView.backgroundColor = AppStyles.backgroundColor
        
        cell.layer.borderWidth = 1
        cell.layer.borderColor = AppStyles.foregroundColor.cgColor
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let page = self.contentPageTypes[indexPath.row]
        self.performSegue(withIdentifier: page.rawValue, sender: page)
    }
    
    
    @objc fileprivate func openPods() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.podSegueId, sender: nil)
    }
        
    @objc fileprivate func openMOC() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.mocSegueId, sender: nil)
    }
    
    @objc fileprivate func openAuCorner() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.auCornerSegueId, sender: nil)
    }
    
    @objc fileprivate func openNormalColumn() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.normalColumnSegueId, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier {
            let vc = segue.destination as! ContentTableViewController
            if id == self.auCornerSegueId {
                vc.contentType = .au
            } else if id == self.normalColumnSegueId {
                vc.contentType = .normalColumn
            } else if id == self.mocSegueId {
                vc.contentType = .moc
            } else {
                vc.contentType = .podcasts
            }
        }
    }
}

class ContentCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
}

class ContentCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override var itemSize: CGSize {
        get {
            let width = (UIScreen.main.bounds.width / 2) - 10
            return CGSize(width: width, height: width)
        } set {}
    }
    
}
