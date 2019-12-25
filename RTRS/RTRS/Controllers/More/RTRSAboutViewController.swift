//
//  RTRSAboutViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSAboutViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    fileprivate var viewModel: RTRSAboutViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = RTRSNavigation.shared.viewModel(for: .about) as? RTRSAboutViewModel
        self.textView.attributedText = self.viewModel?.body ?? NSAttributedString(string: "")
        self.imageView.pin_setImage(from: viewModel?.imageUrl)
        
        self.textView.delegate = self
        self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        
        self.navigationController?.navigationBar.tintColor = .white
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let navController = self.navigationController as? RTRSNavigationController {
            let payload = RTRSDeepLinkPayload(baseURL: URL, title: URL.absoluteString)
            RTRSDeepLinkHandler.route(payload: payload, navController: navController)
        }
        
        return false
    }
}
