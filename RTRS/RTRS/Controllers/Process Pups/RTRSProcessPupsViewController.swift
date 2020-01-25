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
    @IBOutlet weak var collectionView: ProcessPupCollectionView!
    @IBOutlet weak var descriptionTextViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel: RTRSProcessPupsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = (RTRSNavigation.shared.viewModel(for: .processPups) as? RTRSProcessPupsViewModel)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.clipsToBounds = true

        self.descriptionTextView.backgroundColor = .black
        self.descriptionTextViewHeightConstraint.constant = self.descriptionTextView.frame.size.height + 20

        loadingFinished()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .processPupsLoadedNotificationName, object: nil)
    }
    
    @objc private func loadingFinished() {
        self.viewModel = RTRSNavigation.shared.viewModel(for: .processPups) as? RTRSProcessPupsViewModel
        
        self.descriptionTextView.attributedText = self.viewModel.pageDescription
        self.descriptionTextView.sizeToFit()
        
        if let urls = self.viewModel?.pageDescriptionImageURLs {
            self.imageContainer.maxWidth = self.imageContainer.frame.size.width
            self.imageContainer.imgURLs = urls
        }
        
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentHeight: CGFloat = self.descriptionTextView.frame.size.height + 8.0 + self.imageContainer.frame.size.height + 8.0 + self.collectionView.frame.size.height
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: contentHeight + 150.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.processPups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSProcessPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSProcessPupCollectionViewCell
        
        let pup = self.viewModel.processPups[indexPath.row]
        if let url = pup.pupImageURLs?.first {
            cell.clipsToBounds = true
            cell.pupImageView.pin_setImage(from: url)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let pup = self.viewModel.processPups[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: RTRSStandaloneSlideshowViewController.storyboardId) as! RTRSStandaloneSlideshowViewController
        vc.viewModel = self.viewModel
        vc.currentPup = pup
        
        self.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true) {
            
        }
    }
}

class ProcessPupCollectionView: UICollectionView {
    // MARK: - lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.bounds.size.equalTo(self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        get {
            let intrinsicContentSize = self.contentSize
            return intrinsicContentSize
        }
    }
}

class RTRSProcessPupCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var pupImageView: UIImageView!
    
    static let reuseIdentifier = "ProcessPupCell"
    
    override func prepareForReuse() {
        self.pupImageView.image = nil
    }
    
}
