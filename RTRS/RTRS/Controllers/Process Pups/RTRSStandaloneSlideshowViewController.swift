//
//  RTRSStandaloneSlideshowViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/16/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSStandaloneSlideshowViewController: RTRSCollectionViewController, UICollectionViewDataSource {

    @IBOutlet weak var pupNameLabel: UILabel!
    @IBOutlet weak var pupDescriptionTextView: UITextView!
    static let storyboardId = "standalonePups"
    var viewModel: GalleryViewModel!
    var currentPup: GallerySingleEntry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
    }
    
    private func setDescriptionForCurrentPup() {
        let index = self.collectionView.indexOfMajorCell()
        let pup = self.viewModel.entries[index]
        if let description = pup.entryDescription {
            self.pupDescriptionTextView.attributedText = description
        }
        self.pupNameLabel.text = pup.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = self.viewModel.entries.firstIndex(where: { [weak self] (pup) -> Bool in
            guard let weakSelf = self, let name = pup.name, let otherName = weakSelf.currentPup.name else { return false }
            return name == otherName
        }) {
            let page: Int = index
            let contentOffset = CGPoint(x: self.view.frame.size.width * CGFloat(page), y: 0)
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(contentOffset, animated: false)
            }
        }
        
        setDescriptionForCurrentPup()
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.entries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSSlideshowPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSSlideshowPupCollectionViewCell
        let pup = self.viewModel.entries[indexPath.row]
        let url = pup.urls.first!
        cell.imageView.af.setImage(withURL: url, cacheKey: url.absoluteString, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false) { (response) in
            if let image = try? response.result.get() {
                ImageCache.shared.cacheImage(image, identifier: url.absoluteString)
            }
        }
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setDescriptionForCurrentPup()
    }
    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let pup = self.viewModel.processPups[indexPath.row]
//        self.pupDescriptionTextView.attributedText = pup.pupDescription
//    }
//
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        let index = self.collectionView.indexOfMajorCell()
//        let pup = self.viewModel.processPups[index]
//        self.pupDescriptionTextView.attributedText = pup.pupDescription
//    }
}

class RTRSSlideshowPupCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "slideshowPup"
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}
