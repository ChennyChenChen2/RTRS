//
//  RTRSAboutViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSAboutViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    fileprivate var viewModel: RTRSAboutViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = RTRSNavigation.shared.viewModel(for: .about) as? RTRSAboutViewModel
        self.setView()
        self.textView.delegate = self
        self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setView), name: .aboutLoadedNotificationName, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.view.backgroundColor = AppStyles.backgroundColor
        
        self.textView.backgroundColor = AppStyles.backgroundColor
//        self.textView.textColor = AppStyles.foregroundColor
//        self.textView.linkTextAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single, NSAttributedString.Key.underlineColor: AppStyles.foregroundColor]
        
        self.setView()
    }
    
    @objc func setView() {
        guard let bodyText = self.viewModel?.bodyHTML else { return }
        let attrString = NSMutableAttributedString(attributedString:NSAttributedString.attributedStringFrom(htmlString: bodyText))
        let range = NSRange(location: 0, length: attrString.length)
        attrString.removeAttribute(.foregroundColor, range: range)
        attrString.addAttribute(.foregroundColor, value: AppStyles.foregroundColor, range: range)
        attrString.addAttribute(.font, value: Utils.defaultFont, range: range)
        
        self.textView.linkTextAttributes = [.foregroundColor: AppStyles.foregroundColor]
        self.textView.attributedText = attrString
        if let url = viewModel?.imageUrl {
            self.imageView.af.setImage(withURL: url)
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let navController = self.navigationController as? RTRSNavigationController {
            let payload = RTRSDeepLinkPayload(baseURL: URL, title: URL.absoluteString, podURLString: nil, sharingURLString: nil)
            RTRSDeepLinkHandler.route(payload: payload, navController: navController, shouldOpenExternalWebBrowser: true)
        }
        
        return false
    }
}
