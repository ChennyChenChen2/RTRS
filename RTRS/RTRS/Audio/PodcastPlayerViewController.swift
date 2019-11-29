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
    @IBOutlet weak var seekBar: UISlider!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var viewModel: RTRSSinglePodViewModel!
    var sourceViewModel: RTRSPodSourceViewModel?
    var multiPodViewModel: RTRSMultiPodViewModel?

    fileprivate var desiredRate: Float {
        if let rateText = self.rateButton.titleLabel?.text {
            let filteredText = rateText.replacingOccurrences(of: "x", with: "")
            return Float(filteredText) ?? 1.0
        } else {
            return 1.0
        }
    }
    
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
       
        if let viewModel = self.multiPodViewModel, let index = viewModel.content.firstIndex(where: { (vm) -> Bool in
            return vm.title == self.viewModel.title
        }) {
            let pageSize = self.view.bounds.size
            let page: Int = index
            let contentOffset = CGPoint(x: pageSize.width * CGFloat(page), y: 0)
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(contentOffset, animated: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.saveButton.setImage(RTRSPersistentStorage.contentIsAlreadySaved(vm: self.viewModel) ? #imageLiteral(resourceName: "Heart-Fill") : #imageLiteral(resourceName: "Heart-No-Fill"), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if PodcastManager.shared.title == nil || PodcastManager.shared.title! != self.viewModel.title {
            
            if let indexPath = self.multiPodViewModel?.content.firstIndex(where: { (vm) -> Bool in
                return vm.title == self.viewModel.title
            }) {
                self.collectionView.scrollToItem(at: IndexPath(row: indexPath, section: 0), at: .left, animated: false)
            }
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        let manager = PodcastManager.shared
        if manager.isPlaying {
            manager.rate = 0
            manager.pause()
            self.playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        } else {
            manager.rate = self.desiredRate
            manager.play()
            self.playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        PodcastManager.shared.skip(delta: -15.0)
    }
    
    @IBAction func forwardButtonPressed(_ sender: Any) {
        PodcastManager.shared.skip(delta: 15.0)
    }
    
    @IBAction func saveButtonPresssed(_ sender: Any) {
        if RTRSPersistentStorage.contentIsAlreadySaved(vm: self.viewModel) {
            RTRSPersistentStorage.unsaveContent(self.viewModel)
            self.saveButton.setImage(#imageLiteral(resourceName: "Heart-No-Fill"), for: .normal)
        } else {
            RTRSPersistentStorage.saveContent(self.viewModel)
            self.saveButton.setImage(#imageLiteral(resourceName: "Heart-Fill"), for: .normal)
        }
    }
    
    @IBAction func seekBarValueChanged(_ sender: Any) {
        if let duration = PodcastManager.shared.duration?.seconds, let seekBar = sender as? UISlider {
            let value = seekBar.value
            let newElapsed = Double(value) * duration
            let elapsedTime = CMTime(seconds: newElapsed, preferredTimescale: 1)
            self.elapsedLabel.text = TimestampFormatter.timestamp(for: elapsedTime)
        }
    }
    
    @IBAction func seekBarTouchDown(_ sender: Any) {
        PodcastManager.shared.pause()
    }
    
    @IBAction func seekBarTouchUp(_ sender: UISlider) {
        self.seekBar.value = sender.value
        PodcastManager.shared.seek(location: Double(sender.value))
        PodcastManager.shared.play()
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
        if let singlePodViewModel = self.multiPodViewModel?.content[indexPath.row],
            let podDate = singlePodViewModel.dateString,
            let podUrl = self.sourceViewModel?.podUrls[indexPath.row],
            let podTitle = singlePodViewModel.title,
            let podCell = cell as? PodcastCollectionViewCell {
            self.titleLabel.text = podTitle
            self.elapsedLabel.text = "00:00:00"
            self.dateLabel.text = podDate
            
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.isHidden = false
            self.playButton.isHidden = true
            
            if let image = podCell.imageView.image {
                PodcastManager.shared.preparePlayer(title: podTitle, url: podUrl, image: image, dateString: podDate)
            } else if let imageUrl = singlePodViewModel.imageUrl {
                podCell.imageView.pin_setImage(from: imageUrl) { (result) in
                    if result.resultType != .none {
                        if let image = podCell.imageView.image {
                            PodcastManager.shared.preparePlayer(title: podTitle, url: podUrl, image: image, dateString: podDate)
                        }
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! PodcastCollectionViewCell
        
        if let content = self.multiPodViewModel?.content[indexPath.row] as? RTRSSinglePodViewModel, let imageUrl = content.imageUrl {
            cell.imageView.pin_setImage(from: imageUrl)
        }
        
        return cell
    }
    
    // MARK: PodcastManagerDelegate
    func podcastReadyToPlay(duration: CMTime) {
        self.playButton.isHidden = false
        self.playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        
        self.loadingSpinner.stopAnimating()
        self.loadingSpinner.isHidden = true
        
        self.durationLabel.text = "\(TimestampFormatter.timestamp(for: duration))"
        
        PodcastManager.shared.play()
        PodcastManager.shared.rate = self.desiredRate
    }
    
    func podcastTimeDidUpdate(elapsed: CMTime, position: Float) {
        self.seekBar.value = position
        self.elapsedLabel.text = "\(TimestampFormatter.timestamp(for: elapsed))"
    }
    
    func podcastDidFinish() {
        self.playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        PodcastManager.shared.pause()
    }
    
    func podcastDidBeginPlay() {
        self.playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
    }
    
    func podcastDidPause() {
        self.playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
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

fileprivate class TimestampFormatter {
    static func timestamp(for time: CMTime) -> String {
        let seconds = time.seconds
        let hours = modulo(n1: 60.0 * 60.0, n2: seconds)
        var remainingSeconds = seconds.truncatingRemainder(dividingBy: 60.0 * 60.0)
        let minutes = modulo(n1: 60.0, n2: remainingSeconds)
        remainingSeconds = remainingSeconds.truncatingRemainder(dividingBy: 60.0)
        
        return "\(string(for: hours)):\(string(for: minutes)):\(string(for: remainingSeconds))"
    }
    
    private static func string(for digit: Double) -> String {
        if digit == 0.0 {
            return "00"
        } else if digit > 0.0 && digit < 10.0 {
            return "0\(Int(digit))"
        } else {
            return "\(Int(digit))"
        }
    }
    
    private static func modulo(n1: Double, n2: Double) -> Double {
        var result: Double = 0.0
        var sum: Double = 0.0
        while sum + n1 < n2 {
            sum = sum + n1
            result = result + 1.0
        }
        
        return result
    }
}
