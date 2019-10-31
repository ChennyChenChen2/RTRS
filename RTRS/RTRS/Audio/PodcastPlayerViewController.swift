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

class PodcastPlayerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PodcastManagerDelegate {
    
    let cellReuseId = "PodcastCell"
    var player: AVPlayer?
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var seekBar: UIProgressView!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: RTRSSinglePodViewModel!
    var sourceViewModel: RTRSPodSourceViewModel?
    var multiPodViewModel: RTRSMultiPodViewModel?
    var currentIndex: IndexPath?
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.multiPodViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel
        self.sourceViewModel = RTRSNavigation.shared.viewModel(for: .podSource) as? RTRSPodSourceViewModel
        
        PodcastManager.shared.delegate = self
        self.playButton.isHidden = true
        self.loadingSpinner.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = self.multiPodViewModel?.content.firstIndex(where: { (vm) -> Bool in
            return vm.title == self.viewModel.title
        }) {
            self.collectionView.scrollToItem(at: IndexPath(row: indexPath, section: 0), at: .left, animated: false)
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        let manager = PodcastManager.shared
        if manager.rate > 0 {
            manager.rate = 0
            self.playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        } else {
            manager.rate = 1 // TODO: have this reflect a 1.5x or 2x speed
            self.playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        PodcastManager.shared.skip(delta: -15.0)
    }
    
    @IBAction func forwardButtonPressed(_ sender: Any) {
        PodcastManager.shared.skip(delta: 15.0)
    }
    
    @IBAction func rateButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton, let text = button.titleLabel?.text {
            let manager = PodcastManager.shared
            var rate: Float
            switch text {
            case "0.5x":
                rate = 0.8
                break
            case "0.8x":
                rate = 1.0
            case "1.0x":
                rate = 1.25
                break
            case "1.25x":
                rate = 1.5
                break
            case "1.5x":
                rate = 2.0
                break
            case "2.0x":
                rate = 3.0
                break
            case "3.0x":
                rate = 0.5
                break
            default:
                return
            }
            manager.rate = rate
            button.setTitle("\(rate)x", for: .normal)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.multiPodViewModel?.content.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let singlePodViewModel = self.multiPodViewModel?.content[indexPath.row], let podTitle = singlePodViewModel.title, let podUrl = self.sourceViewModel?.pods[podTitle], let podCell = cell as? PodcastCollectionViewCell, let image = podCell.imageView.image {
            self.titleLabel.text = podTitle
            self.dateLabel.text = singlePodViewModel.dateString
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
    
    // MARK: PodcastManagerDelegate
    func podcastReadyToPlay() {
        self.playButton.isHidden = false
        self.playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        
        self.loadingSpinner.stopAnimating()
        self.loadingSpinner.isHidden = true
        PodcastManager.shared.player?.play()
    }
}

class PodcastCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}

class RTRSCustomCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func awakeFromNib() {
        guard let collectionView = self.collectionView else { return }
        self.minimumInteritemSpacing = 0.0;
        self.minimumLineSpacing = 0.0;
        self.scrollDirection = .horizontal;
        self.sectionInset = UIEdgeInsets.zero
        let contentInset = collectionView.contentInset
        self.itemSize = CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height - 1 - contentInset.top - contentInset.bottom)
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
}
