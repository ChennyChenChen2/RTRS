//
//  MultiPhotoContainerView.swift
//  RTRS
//
//  Created by Jonathan Chen on 12/8/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class MultiPhotoContainerView: UIView {
    
    var imgURLs: [URL] {
        didSet {
            self.layoutSubviews()
        }
    }
    
    var maxWidth: CGFloat
    private var imageViews: [UIImageView]
    
    required init(urls: [URL], maxWidth: CGFloat) {
        self.imgURLs = urls
        self.imageViews = [UIImageView]()
        self.maxWidth = maxWidth
        super.init(frame: CGRect())
    }
    
    required init?(coder: NSCoder) {
        self.imgURLs = [URL]()
        self.imageViews = [UIImageView]()
        self.maxWidth = CGFloat(Int.max)
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        if self.imageViews.count > 0 {
            for view in self.imageViews {
                view.removeFromSuperview()
            }
            
            self.imageViews = []
        }
        
        let horizontalSpacing: CGFloat = 5.0
        let imageWidth = self.maxWidth / CGFloat(self.imgURLs.count)
                
        for i in 0..<self.imgURLs.count {
            let url = self.imgURLs[i]
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.frame.size.width = imageWidth
            imageView.af.setImage(withURL: url, cacheKey: nil, placeholderImage: nil, serializer: nil, filter: nil, progress: nil, progressQueue: .main, imageTransition: .crossDissolve(1.0), runImageTransitionIfCached: false) { [weak self] (result) in
                guard let weakSelf = self, result.error == nil else { return }
                imageView.sizeToFit()
                
                let aspectRatio = imageView.frame.size.width / imageView.frame.size.height
                let newHeight = imageWidth * (1 / aspectRatio)
                
                imageView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: newHeight)
                weakSelf.addSubview(imageView)
                weakSelf.imageViews.append(imageView)
                if i == weakSelf.imgURLs.count - 1 {
                    var prevImageView: UIImageView?
                    for imageView in weakSelf.imageViews {
                        if let pIV = prevImageView {
                            imageView.frame.origin.x = pIV.frame.origin.x + pIV.frame.size.width + horizontalSpacing
                        } else {
                            imageView.frame.origin.x = horizontalSpacing
                        }
                        
                        prevImageView = imageView
                    }
                    
                    weakSelf.sizeToFit()
                }
            }
            
//            imageView.pin_setImage(from: url) { [weak self] (result) in
//                guard let weakSelf = self, result.error == nil else { return }
//                imageView.sizeToFit()
//
//                let aspectRatio = imageView.frame.size.width / imageView.frame.size.height
//                let newHeight = imageWidth * (1 / aspectRatio)
//
//                imageView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: newHeight)
//                weakSelf.addSubview(imageView)
//                weakSelf.imageViews.append(imageView)
//                if i == weakSelf.imgURLs.count - 1 {
//                    var prevImageView: UIImageView?
//                    for imageView in weakSelf.imageViews {
//                        if let pIV = prevImageView {
//                            imageView.frame.origin.x = pIV.frame.origin.x + pIV.frame.size.width + horizontalSpacing
//                        } else {
//                            imageView.frame.origin.x = horizontalSpacing
//                        }
//
//                        prevImageView = imageView
//                    }
//
//                    weakSelf.sizeToFit()
//                }
//            }
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
