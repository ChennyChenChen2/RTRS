//
//  AUCornerTableViewCell.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/7/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class AUCornerTableViewCell: UITableViewCell {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var auTitleLabel: UILabel!
    @IBOutlet weak var auDescriptionLabel: UILabel!
    @IBOutlet weak var auTimestampLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.previewImageView.image = nil
    }
    
    func applyViewModel(viewModel: AUCornerSingleArticleViewModel) {
        self.auTitleLabel.text = viewModel.title
        self.auDescriptionLabel.text = viewModel.description
        self.auTimestampLabel.text = viewModel.dateString
        
        if let imageUrl = viewModel.imageUrl {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: imageUrl) { [weak self] (data, response, error) in
                if let theData = data, let weakSelf = self {
                    DispatchQueue.main.async {
                        weakSelf.previewImageView.image = UIImage(data: theData)
                    }
                }
            }
            task.resume()
        }
    }

}
