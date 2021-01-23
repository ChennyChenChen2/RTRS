//
//  GalleryViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/8/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, LoggableViewController  {

    @IBOutlet weak var descriptionTextView: UITextView?
    @IBOutlet weak var imageContainer: MultiPhotoContainerView?
    @IBOutlet weak var collectionView: ProcessPupCollectionView?
    @IBOutlet weak var galleryTitleLabel: UILabel!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    
    var contentType: RTRSScreenType?
    var viewModel: GalleryViewModel!
    func viewModelForLogging() -> RTRSViewModel? {
        return viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let type = contentType else { return }
        self.viewModel = (RTRSNavigation.shared.viewModel(for: type) as? GalleryViewModel)
        self.navigationItem.title = type.rawValue
        
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.clipsToBounds = true

        self.descriptionTextView?.smartQuotesType = .yes

        loadingFinished()
        
        switch contentType {
        case .abbie:
            NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .abbieLoadedNotificationName, object: nil)
        case .processPups:
            NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .processPupsLoadedNotificationName, object: nil)
        case .goodDogClub:
            NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished), name: .processPupsLoadedNotificationName, object: nil)
        default: break
        }
    }
    
    @objc private func loadingFinished() {
        guard let type = contentType else { return }
        self.viewModel = (RTRSNavigation.shared.viewModel(for: type) as? GalleryViewModel)
        
        self.descriptionTextView?.attributedText = self.viewModel.pageDescription
        
        if let urls = self.viewModel?.pageDescriptionImageURLs, let imageContainer = self.imageContainer {
            imageContainer.maxWidth = imageContainer.frame.size.width
            self.imageContainer?.imgURLs = urls
        }
        
        self.collectionView?.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor]
        
        self.view.backgroundColor = AppStyles.backgroundColor
        
        self.galleryTitleLabel.textColor = AppStyles.foregroundColor
        
        self.descriptionTextView?.backgroundColor = AppStyles.backgroundColor
        self.descriptionTextView?.textColor = AppStyles.foregroundColor
        self.descriptionTextView?.linkTextAttributes = [.foregroundColor: AppStyles.foregroundColor]
        
        self.imageContainer?.backgroundColor = AppStyles.backgroundColor
        self.collectionView?.backgroundColor = AppStyles.backgroundColor
        
        if PodcastManager.shared.playerViewIsShowing {
            self.collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.viewModel.pageDescription == nil {
            self.descriptionTextView?.removeFromSuperview()
        }
        
        if self.viewModel.pageDescriptionImageURLs == nil || self.viewModel.pageDescriptionImageURLs!.count == 0 {
            self.imageContainerHeightConstraint?.constant = 0
            self.imageContainer?.removeFromSuperview()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.entries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSProcessPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSProcessPupCollectionViewCell
        
        let pup = self.viewModel.entries[indexPath.row]
        if let url = pup.urls.first {
            cell.clipsToBounds = true
            cell.pupImageView.af.setImage(withURL: url, cacheKey: nil, placeholderImage: #imageLiteral(resourceName: "RickyLogoCutout"), serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false, completion: nil)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pup = self.viewModel.entries[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: RTRSStandaloneSlideshowViewController.storyboardId) as! RTRSStandaloneSlideshowViewController
        vc.viewModel = self.viewModel
        vc.currentEntry = pup
        
        self.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
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
