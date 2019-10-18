//
//  PodcastPlayerViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/15/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import PINRemoteImage
import MarqueeLabel
import AVFoundation

class PodcastPlayerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let cellReuseId = "PodcastCell"
    var player: AVPlayer?
    
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: RTRSSinglePodViewModel!
    var sourceViewModel: RTRSPodSourceViewModel?
    var multiPodViewModel: RTRSMultiPodViewModel?
    var currentIndex: IndexPath?
    var didScroll = false
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.multiPodViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel
        self.sourceViewModel = RTRSNavigation.shared.viewModel(for: .podSource) as? RTRSPodSourceViewModel
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = self.multiPodViewModel?.content.firstIndex(where: { (vm) -> Bool in
            return vm.title == self.viewModel.title
        }) {
            self.collectionView.scrollToItem(at: IndexPath(row: indexPath, section: 0), at: .centeredHorizontally, animated: false)
        }
        didScroll = true
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.multiPodViewModel?.content.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let podTitle = self.viewModel.title, let podUrl = self.sourceViewModel?.pods[podTitle], let podCell = cell as? PodcastCollectionViewCell, let image = podCell.imageView.image {
            self.titleLabel.text = podTitle
            self.dateLabel.text = self.viewModel.dateString
            PodcastManager.shared.preparePlayer(title: podTitle, url: podUrl, image: image)
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! PodcastCollectionViewCell
        
        if let content = self.multiPodViewModel?.content[indexPath.row] as? RTRSSinglePodViewModel, let imageUrl = content.imageUrl {
//            self.viewModel = content
            cell.imageView.pin_setImage(from: imageUrl)
        }
        
        return cell
    }
}

class PodcastCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    
}

class RTRSCustomCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func awakeFromNib() {
        guard let collectionView = self.collectionView else { return }
        self.itemSize = CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
        self.minimumInteritemSpacing = 0.0;
        self.minimumLineSpacing = 0.0;
        self.scrollDirection = .horizontal;
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        
        guard let collectionView = self.collectionView else { return CGPoint.zero }
        
//        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        var offsetAdjustment: CGFloat = 0.0
        let horizontalOffset = proposedContentOffset.x + 5
        
        let targetRect = CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
        
        if let attributes = super.layoutAttributesForElements(in: targetRect) {
            for attribute in attributes {
                let itemOffset = attribute.frame.origin.x
//                if abs(itemOffset - horizontalOffset) < abs(offsetAdjustment) {
                offsetAdjustment = offsetAdjustment + itemOffset
//                }
            }
        }
        
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
    
//    - (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
//    {
//        CGFloat offsetAdjustment = MAXFLOAT;
//        CGFloat horizontalOffset = proposedContentOffset.x + 5;
//
//        CGRect targetRect = CGRectMake(proposedContentOffset.x, 0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
//
//        NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
//
//        for (UICollectionViewLayoutAttributes *layoutAttributes in array) {
//            CGFloat itemOffset = layoutAttributes.frame.origin.x;
//            if (ABS(itemOffset - horizontalOffset) < ABS(offsetAdjustment)) {
//                offsetAdjustment = itemOffset - horizontalOffset;
//            }
//        }
//
//        return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
//    }
    
}
