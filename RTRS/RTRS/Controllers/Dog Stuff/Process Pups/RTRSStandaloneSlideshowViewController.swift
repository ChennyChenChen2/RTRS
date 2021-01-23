//
//  RTRSStandaloneSlideshowViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/16/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSStandaloneSlideshowViewController: RTRSCollectionViewController, UICollectionViewDataSource {

    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    static let storyboardId = "standalonePups"
    var viewModel: GalleryViewModel!
    var currentEntry: GallerySingleEntry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
    }
    
    private func setDescription(for entry: GallerySingleEntry) {
        if let description = entry.entryDescriptionHTML {
            let attrString = NSMutableAttributedString(attributedString: NSAttributedString.attributedStringFrom(htmlString: description))
            let range = NSRange(location: 0, length: attrString.length)
            attrString.removeAttribute(.foregroundColor, range: range)
            attrString.addAttribute(.foregroundColor, value: AppStyles.foregroundColor, range: range)
            attrString.addAttribute(.font, value: Utils.defaultFont, range: range)
            self.descriptionTextView.attributedText = attrString
        }
        self.nameLabel.text = entry.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = AppStyles.backgroundColor
        self.descriptionTextView.backgroundColor = AppStyles.backgroundColor
        
        self.nameLabel.textColor = AppStyles.foregroundColor
        self.descriptionTextView.textColor = AppStyles.foregroundColor
        self.descriptionTextView.linkTextAttributes = [.foregroundColor: AppStyles.foregroundColor]
        self.dismissButton.tintColor = AppStyles.foregroundColor
        
        self.setDescription(for: self.currentEntry)
        self.collectionView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let index = self.viewModel.entries.firstIndex(where: { [weak self] (entry) -> Bool in
            guard let weakSelf = self, let otherEntry = weakSelf.currentEntry else { return false }
            return otherEntry == entry
        }) {
            let page: Int = index
            let contentOffset = CGPoint(x: self.view.frame.size.width * CGFloat(page), y: 0)
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(contentOffset, animated: false)
                self.collectionView.alpha = 1
            }
        }
        
        AnalyticsUtils.logViewGalleryEntry("\(self.viewModel.pageName()): \(currentEntry.name ?? "No name")")
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.entries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let entryCell = cell as? RTRSSlideshowPupCollectionViewCell else { return }
        let entry = self.viewModel.entries[indexPath.row]
        let url = entry.urls.first!
        entryCell.contentView.backgroundColor = AppStyles.backgroundColor
        entryCell.backgroundColor = AppStyles.backgroundColor
        entryCell.imageView.af.setImage(withURL: url, cacheKey: url.absoluteString, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false) { (response) in
            if let image = try? response.result.get() {
                entryCell.imageView.image = image
                ImageCache.shared.cacheImage(image, identifier: url.absoluteString)
            }
        }
        
        self.setDescription(for: entry)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSSlideshowPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSSlideshowPupCollectionViewCell
        let entry = self.viewModel.entries[indexPath.row]
        let url = entry.urls.first!
        cell.imageView.af.setImage(withURL: url, cacheKey: url.absoluteString, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false) { (response) in
            if let image = try? response.result.get() {
                ImageCache.shared.cacheImage(image, identifier: url.absoluteString)
            }
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard self.collectionView.indexPathsForVisibleItems.count == 1 else { return }
        let indexPath = self.collectionView.indexPathsForVisibleItems[0]
        let entry = self.viewModel.entries[indexPath.row]
        self.currentEntry = entry
        self.setDescription(for: entry)
    }
}

class RTRSSlideshowPupCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "slideshowPup"
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}
