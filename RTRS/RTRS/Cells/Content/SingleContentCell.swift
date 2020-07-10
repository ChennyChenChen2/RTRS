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
//            self.previewImageView.pin_setImage(from: imageUrl, placeholderImage: #imageLiteral(resourceName: "RickyLogoCutout"))
            self.previewImageView.af_setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "RickyLogoCutout"), filter: nil, progress: nil, progressQueue: .global(), imageTransition: .crossDissolve(1.0), runImageTransitionIfCached: false, completion: nil)
        }
    }
    
    override func prepareForReuse() {
        self.previewImageView.image = nil
    }
}
