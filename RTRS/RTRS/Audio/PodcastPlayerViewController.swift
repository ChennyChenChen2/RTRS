//
//  PodcastPlayerViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/15/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import AlamofireImage
import MarqueeLabel
import AVFoundation

class PodcastPlayerViewController: RTRSCollectionViewController, UICollectionViewDataSource, PodcastManagerDelegate {
    
    let cellReuseId = "PodcastCell"
    var player: AVPlayer?
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var seekBar: UISlider!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var displayedViaTabView = false
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
        
        self.collectionView.dataSource = self

        self.multiPodViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel
        self.sourceViewModel = RTRSNavigation.shared.viewModel(for: .podSource) as? RTRSPodSourceViewModel
        
        PodcastManager.shared.delegate = self
        self.playButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.saveButton.setImage(RTRSPersistentStorage.contentIsAlreadySaved(vm: self.viewModel) ? #imageLiteral(resourceName: "Heart-Fill") : #imageLiteral(resourceName: "Heart-No-Fill"), for: .normal)
        
        if !self.displayedViaTabView && (PodcastManager.shared.title == nil || PodcastManager.shared.title! != self.viewModel.title) {
            self.displayedViaTabView = false
            if let indexPath = self.multiPodViewModel?.content.firstIndex(where: { (vm) -> Bool in
                guard let vm = vm else { return false }
                return vm.title == self.viewModel.title
            }) {
                let page: Int = indexPath
                let contentOffset = CGPoint(x: self.view.frame.size.width * CGFloat(page), y: 0)
                DispatchQueue.main.async {
                    self.collectionView.setContentOffset(contentOffset, animated: false)
                    self.collectionView.reloadData()
                }
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
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
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
                podCell.imageView.af.setImage(withURL: imageUrl, cacheKey: imageUrl.absoluteString, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .crossDissolve(1.0), runImageTransitionIfCached: false) { (response) in
                    if let image = response.value {
                        podCell.imageView.image = image
                        PodcastManager.shared.preparePlayer(title: podTitle, url: podUrl, image: image, dateString: podDate)
                    }
                }
            } else {
                print("PodcastPlayerViewController cannot display image?")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! PodcastCollectionViewCell
        
        if let content = self.multiPodViewModel?.content[indexPath.row] as? RTRSSinglePodViewModel, let imageUrl = content.imageUrl {
            cell.imageView.af.setImage(withURL: imageUrl)
        } else {
            print("HERE?")
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

class RTRSCollectionViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
    }
}

class PodcastCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        self.imageView.image = nil
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

extension UICollectionView {
    func indexOfMajorCell() -> Int {
        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemWidth = layout.itemSize.width
            let proportionalOffset = layout.collectionView!.contentOffset.x / itemWidth
            let index = Int(round(proportionalOffset))
            let numberOfItems = self.numberOfItems(inSection: 0)
            let safeIndex = max(0, min(numberOfItems - 1, index))
            return safeIndex
        }
        
        return 0
    }
}
 
 class RTRSCustomCollectionViewFlowLayout: UICollectionViewFlowLayout {
     
     override var minimumLineSpacing: CGFloat {
         get {
             return 0.0
         } set {}
     }
     
     override var minimumInteritemSpacing: CGFloat {
         get {
             return 0.0
         } set {}
     }
     
     override var sectionInset: UIEdgeInsets {
         get {
             return .zero
         } set {}
     }
     
     override var itemSize: CGSize {
         get {
             guard let collectionView = self.collectionView else { return .zero }
             let contentInset = collectionView.contentInset
             return CGSize(width: collectionView.frame.size.width - contentInset.left - contentInset.right, height: collectionView.frame.size.height - contentInset.top - contentInset.bottom - 1)
         } set {}
     }
   
     override func awakeFromNib() {
         self.scrollDirection = .horizontal
     }
 }
