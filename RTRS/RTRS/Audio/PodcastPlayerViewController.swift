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

class PodcastPlayerViewController: RTRSCollectionViewController, UICollectionViewDataSource, PodcastManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    private let kInfoTooltipSeenDefaultwsKey = "kInfoTooltipSeen"
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
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var youtubeButton: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var infoButton: UIButton!
    
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
    
    fileprivate var infoTooltipSeen: Bool {
        get {
            return UserDefaults.standard.bool(forKey: kInfoTooltipSeenDefaultwsKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: kInfoTooltipSeenDefaultwsKey)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemPlayedToEndAction), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateViewModels), name: Notification.Name.podLoadedNotificationName, object: nil)
    }
    
    @objc private func updateViewModels() {
        self.multiPodViewModel = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel
        self.sourceViewModel = RTRSNavigation.shared.viewModel(for: .podSource) as? RTRSPodSourceViewModel
    }
    
    @objc private func itemPlayedToEndAction() {
        let indexPaths = self.collectionView.indexPathsForVisibleItems
        if let path = indexPaths.first, path.row < self.collectionView.numberOfItems(inSection: 0) - 1 {
            let nextPath = IndexPath(item: path.row + 1, section: 0)
            self.collectionView.scrollToItem(at: nextPath, at: .centeredHorizontally, animated: true)
            
            self.durationLabel.text = "00:00:00"
            self.seekBar.value = 0
            
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.isHidden = false
            self.playButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = AppStyles.backgroundColor
        self.seekBar.minimumTrackTintColor = .blue
        self.seekBar.maximumTrackTintColor = .gray
        
        self.youtubeButton.contentHorizontalAlignment = .fill
        self.youtubeButton.contentVerticalAlignment = .fill
        self.youtubeButton.tintColor = AppStyles.foregroundColor
        self.backButton.tintColor = AppStyles.foregroundColor
        self.forwardButton.tintColor = AppStyles.foregroundColor
        self.playButton.tintColor = AppStyles.foregroundColor
        self.shareButton.tintColor = AppStyles.foregroundColor
        self.infoButton.tintColor = AppStyles.foregroundColor
        self.rateButton.setTitleColor(AppStyles.foregroundColor, for: .normal)
        self.loadingSpinner.color = AppStyles.foregroundColor
        self.durationLabel.textColor = AppStyles.foregroundColor
        self.elapsedLabel.textColor = AppStyles.foregroundColor
        self.dateLabel.textColor = AppStyles.foregroundColor
        self.titleLabel.textColor = AppStyles.foregroundColor
        
        self.saveButton.setImage(AppStyles.likeIcon(for: self.viewModel), for: .normal)
        self.shareButton.setImage(AppStyles.shareIcon, for: .normal)

        self.dismissButton.tintColor = AppStyles.foregroundColor
        
        // If this check fails, VC can get in a weird state with the wrong viewModel. Might want to keep old viewModel
        // until we know the check has succeeded.
        if !self.displayedViaTabView && (PodcastManager.shared.title == nil || PodcastManager.shared.title! != self.viewModel.title) {
            if let indexPath = self.multiPodViewModel?.content.firstIndex(where: { (vm) -> Bool in
                guard let vm = vm as? RTRSSinglePodViewModel else { return false }
                return vm.sharingUrl == self.viewModel.sharingUrl
            }) {
                let page: Int = indexPath
                let contentOffset = CGPoint(x: self.view.frame.size.width * CGFloat(page), y: 0)
                DispatchQueue.main.async {
                    self.collectionView.setContentOffset(contentOffset, animated: false)
                    self.collectionView.reloadData()
                }
            }
        }
        
        self.displayedViaTabView = false
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        guard let button = sender as? UIButton, let summary = self.viewModel.podSummary else { return }
        let popoverContentController = PopoverTextViewController(text: summary)
        popoverContentController.preferredContentSize = popoverContentController.textView.intrinsicContentSize
        popoverContentController.modalPresentationStyle = .popover
         
        if let popoverPresentationController = popoverContentController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .down
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = button.frame
            popoverPresentationController.delegate = self
            present(popoverContentController, animated: true, completion: nil)
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
    }
     
    //UIPopoverPresentationControllerDelegate
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
     
    }
     
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
    return true
    }
    
    @IBAction func youtubeAction(_ sender: Any) {
        if let youtubeURL = self.viewModel.youtubeUrl {
            PodcastManager.shared.pause()
            RTRSExternalWebViewController.openExternalWebBrowser(self, url: youtubeURL as URL, name: "RTRS on Youtube")
            
            if let title = self.viewModel.title {
                AnalyticsUtils.logYoutubeButtonPressed(title)
            }
        }
    }
    
    @IBAction func shareAction() {
         guard let url = viewModel?.sharingUrl else { return }

        // set up activity view controller
        let itemToShare = [ url ]
        
        let activityViewController = UIActivityViewController(activityItems: itemToShare, applicationActivities: [])
        activityViewController.popoverPresentationController?.sourceView = self.view

        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
        if let absString = url.absoluteString {
            AnalyticsUtils.logShare(absString)
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        let manager = PodcastManager.shared
        if manager.isPlaying {
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
        } else {
            RTRSPersistentStorage.saveContent(self.viewModel)
        }
        
        self.saveButton.setImage(AppStyles.likeIcon(for: self.viewModel), for: .normal)
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
    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! PodcastCollectionViewCell
        let content = self.multiPodViewModel?.content
        let source = self.sourceViewModel
        assert(content != nil && indexPath.row < content!.count)
        assert(source != nil && indexPath.row < source!.podInfo.count)
        
        if let content = content, let source = source, indexPath.row < content.count, indexPath.row < source.podInfo.count, let singlePodViewModel = content[indexPath.row] as? RTRSSinglePodViewModel,
            let podDate = singlePodViewModel.dateString,
            let podUrl = source.podInfo[indexPath.row].link,
            let podTitle = singlePodViewModel.title {
            self.titleLabel.text = podTitle
            self.elapsedLabel.text = "00:00:00"
            self.dateLabel.text = podDate
            self.viewModel = singlePodViewModel
            
            if self.viewModel?.podSummary == nil || self.viewModel?.youtubeUrl == nil {
                let spinner = UIActivityIndicatorView()
                if self.buttonStackView.arrangedSubviews.count > 1 {
                    self.buttonStackView.insertArrangedSubview(spinner, at: 1)
                } else {
                    // Just to account for any possible index out of bounds issues
                    self.buttonStackView.addArrangedSubview(spinner)
                }
                self.youtubeButton.isHidden = true
                self.infoButton.isHidden = true
                spinner.hidesWhenStopped = true
                spinner.startAnimating()
                self.viewModel.lazyLoadPodData {
                    DispatchQueue.main.async {
                        spinner.stopAnimating()
                        self.buttonStackView.removeArrangedSubview(spinner)
                        self.youtubeButton.isHidden = singlePodViewModel.youtubeUrl == nil
                        self.infoButton.isHidden = singlePodViewModel.podSummary == nil
                        
                        self.multiPodViewModel?.content[indexPath.row] = singlePodViewModel
                        if let multiPodVM = self.multiPodViewModel {
                            RTRSPersistentStorage.save(viewModel: multiPodVM, type: .podcasts)
                        }
                        
                        if !self.infoTooltipSeen {
                            Utils.showToolTip(in: self.infoButton, title: "Tap here to read pod description", message: "Pod will continue playing as you read", identifier: "Pod info button", direction: .bottom)
                            self.infoTooltipSeen = true
                        }
                    }
                }
            } else {
                self.youtubeButton.isHidden = false
            }
            
            cell.contentView.backgroundColor = AppStyles.backgroundColor
            
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.isHidden = false
            self.playButton.isHidden = true
            
            PodcastManager.shared.preparePlayer(title: podTitle, url: podUrl as URL, dateString: podDate)
            
            if let image = cell.imageView.image {
                PodcastManager.shared.configureNowPlayingInfo(image: image)
            } else if let imageUrl = singlePodViewModel.imageUrl {
                cell.imageView.af.setImage(withURL: imageUrl as URL, cacheKey: imageUrl.absoluteString, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .global(), imageTransition: .noTransition, runImageTransitionIfCached: false) { (response) in
                    if let image = response.value {
                        cell.imageView.image = image
                        PodcastManager.shared.configureNowPlayingInfo(image: image)
                    } else {
                        print("No image?")
                    }
                }
            } else {
                print("PodcastPlayerViewController cannot display image?")
            }
        }
        
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! PodcastCollectionViewCell
//
//        if let content = self.multiPodViewModel?.content[indexPath.row] as? RTRSSinglePodViewModel, let imageUrl = content.imageUrl {
//            cell.imageView.af.setImage(withURL: imageUrl as URL)
//        } else {
//            print("HERE?")
//        }
//
//        return cell
//    }
    
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
        self.playButton.isHidden = false
        
        self.loadingSpinner.stopAnimating()
        self.loadingSpinner.isHidden = true
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

fileprivate class PopoverTextViewController: UIViewController {
    let textView = UITextView()
    
    init(text: String) {
        self.textView.font = Utils.defaultFont
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.isUserInteractionEnabled = false
        self.textView.text = text
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = AppStyles.backgroundColor
        self.textView.backgroundColor = AppStyles.backgroundColor
        self.textView.textColor = AppStyles.foregroundColor

    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.addSubview(self.textView)
        self.textView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant:10).isActive = true
        self.textView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant:-10).isActive = true
        self.textView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10).isActive = true
        self.textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
    }
}
