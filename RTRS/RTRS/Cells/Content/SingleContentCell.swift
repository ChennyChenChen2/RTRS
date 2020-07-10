//
//  AUCornerTableViewCell.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/7/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import AlamofireImage

class SingleContentCell: UITableViewCell {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet weak var auDescriptionLabel: UILabel!
    @IBOutlet weak var auTimestampLabel: UILabel!
    
    func applyViewModel(viewModel: SingleContentViewModel) {
        self.contentTitleLabel.text = viewModel.title
        self.auDescriptionLabel.text = viewModel.contentDescription
        self.auTimestampLabel.text = viewModel.dateString
        
        if let imageUrl = viewModel.imageUrl {
            self.previewImageView.af.setImage(withURL: imageUrl, cacheKey: imageUrl.absoluteString, placeholderImage: #imageLiteral(resourceName: "RickyLogoCutout"), serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .crossDissolve(0.5), runImageTransitionIfCached: false) { (response) in
                if let image = try? response.result.get() {
                    ImageCache.shared.cacheImage(image, identifier: imageUrl.absoluteString)
                }
            }
        }
    }
    
    override func prepareForReuse() {
        self.previewImageView.image = nil
    }
}

class ImageCache {
    static let shared = ImageCache()
    private let cache = AutoPurgingImageCache()
    private init() {}
    
    func cacheImage(_ image: UIImage, identifier: String) {
        cache.add(image, withIdentifier: identifier)
    }
}
