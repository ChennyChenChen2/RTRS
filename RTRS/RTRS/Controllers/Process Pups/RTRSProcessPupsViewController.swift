//
//  RTRSProcessPupsViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/8/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSProcessPupsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imageContainer: MultiPhotoContainerView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var descriptionTextViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel: RTRSProcessPupsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = (RTRSNavigation.shared.viewModel(for: .processPups) as! RTRSProcessPupsViewModel)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.descriptionTextView.backgroundColor = .black
        self.descriptionTextView.textColor = .white
        self.descriptionTextView.text = self.viewModel.pageDescription
        self.descriptionTextView.font = Utils.defaultFont
        self.descriptionTextView.sizeToFit()
        self.descriptionTextViewHeightConstraint.constant = self.descriptionTextView.frame.size.height
        
        if let urls = self.viewModel?.pageDescriptionImageURLs {
            self.imageContainer.maxWidth = self.imageContainer.frame.size.width
            self.imageContainer.imgURLs = urls
        }
        
        let contentHeight: CGFloat = self.descriptionTextView.frame.size.height + 8.0 + self.imageContainer.frame.size.height + 8.0 + self.collectionView.frame.size.height
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: contentHeight + 50.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.processPups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSProcessPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSProcessPupCollectionViewCell
        
        let pup = self.viewModel.processPups[indexPath.row]
        if let url = pup.pupImageURLs?.first {
            cell.pupImageView.pin_setImage(from: url)
        }
        
        return cell
    }
}

class RTRSProcessPupCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var pupImageView: UIImageView!
    
    static let reuseIdentifier = "ProcessPupCell"
    
}
