//
//  AUCornerTableViewCell.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/7/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import PINRemoteImage

class AUCornerTableViewCell: UITableViewCell {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var auTitleLabel: UILabel!
    @IBOutlet weak var auDescriptionLabel: UILabel!
    @IBOutlet weak var auTimestampLabel: UILabel!
    
    func applyViewModel(viewModel: AUCornerSingleArticleViewModel) {
        self.auTitleLabel.text = viewModel.title
        self.auDescriptionLabel.text = viewModel.articleDescription
        self.auTimestampLabel.text = viewModel.dateString
        
        if let imageUrl = viewModel.imageUrl {
            self.previewImageView.pin_setImage(from: imageUrl)
        }
    }
}
