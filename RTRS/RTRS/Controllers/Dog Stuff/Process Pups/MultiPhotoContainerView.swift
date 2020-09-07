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
    private var _intrinsicSize: CGSize = CGSize.zero
    
    override var intrinsicContentSize: CGSize {
        return _intrinsicSize
    }
    
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
                    var maxX: CGFloat = 0
                    var maxY: CGFloat = 0
                    for imageView in weakSelf.imageViews {
                        if maxX < imageView.frame.maxX {
                            maxX = imageView.frame.maxX
                        }
                        
                        if maxY < imageView.frame.maxY {
                            maxY = imageView.frame.maxY
                        }
                        
                        if let pIV = prevImageView {
                            imageView.frame.origin.x = pIV.frame.origin.x + pIV.frame.size.width + horizontalSpacing
                        } else {
                            imageView.frame.origin.x = horizontalSpacing
                        }
                        
                        prevImageView = imageView
                    }
                    
                    weakSelf._intrinsicSize = CGSize(width: maxX, height: maxY)
                    weakSelf.invalidateIntrinsicContentSize()
                    print("HERE")
                }
            }
        }
    }
}
