//
//  RTRSStandaloneSlideshowViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/16/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSStandaloneSlideshowViewController: RTRSCollectionViewController, UICollectionViewDataSource {

    @IBOutlet weak var pupDescriptionTextView: UITextView!
    static let storyboardId = "standalonePups"
    var viewModel: RTRSProcessPupsViewModel!
    var currentPup: ProcessPup!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.dataSource = self
    }
    
    private func setDescriptionForCurrentPup() {
        let index = self.collectionView.indexOfMajorCell()
        let pup = self.viewModel.processPups[index]
        self.pupDescriptionTextView.attributedText = pup.pupDescription
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = self.viewModel.processPups.firstIndex(where: { [weak self] (pup) -> Bool in
            guard let weakSelf = self, let name = pup.pupName, let otherName = weakSelf.currentPup.pupName else { return false }
            return name == otherName
        }) {
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let page: Int = index
                let contentOffset = CGPoint(x: layout.itemSize.width * CGFloat(page), y: 0)
                DispatchQueue.main.async {
                    self.collectionView.setContentOffset(contentOffset, animated: false)
                }
            }
        }
        
        setDescriptionForCurrentPup()
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.processPups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RTRSSlideshowPupCollectionViewCell.reuseIdentifier, for: indexPath) as! RTRSSlideshowPupCollectionViewCell
        let pup = self.viewModel.processPups[indexPath.row]
        cell.imageView.pin_setImage(from: pup.pupImageURLs!.first!)
        
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
