//
//  AUCornerArticleViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/8/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import WebKit

class AUCornerArticleViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel: AUCornerSingleArticleViewModel?
    var webView: WKWebView?
    var webViewContentObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        self.scrollView.backgroundColor = .black
        
        self.imageView.pin_setImage(from: self.viewModel?.imageUrl)
        
        self.titleLabel.text = self.viewModel?.title
        self.titleLabel.textColor = .white
        self.titleLabel.alpha = 0.8
        self.titleLabel.layer.borderWidth = 1.0
        self.titleLabel.layer.borderColor = UIColor.white.cgColor
        self.titleLabel.layer.backgroundColor = UIColor.black.cgColor
        
        self.dateLabel.text = self.viewModel?.dateString
        
        self.webView = WKWebView(frame: self.webViewContainer.frame)
        self.webView?.scrollView.isScrollEnabled = false
        self.webView?.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0.0, bottom: 5.0, right: 5.0)
        
        self.webView?.translatesAutoresizingMaskIntoConstraints = false
        self.webView?.navigationDelegate = self
        self.webViewContainer.addSubview(self.webView!)
        if let htmlString = self.viewModel?.htmlString, let baseURL = self.viewModel?.baseURL {
            self.webView?.loadHTMLString(htmlString, baseURL: baseURL)
        }
        
        if let webView = self.webView {
            self.webViewContentObservation = webView.observe(\WKWebView.scrollView.contentSize, changeHandler: { [weak self] (object, change) in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.webViewHeightConstraint.constant = object.scrollView.contentSize.height
                    weakSelf.view.setNeedsLayout()
                    weakSelf.view.layoutIfNeeded()
                }
            })
        }
    }
    
    deinit {
        self.webViewContentObservation = nil
    }
    
    override func viewWillLayoutSubviews() {
        self.webView?.leftAnchor.constraint(equalTo: self.webViewContainer.leftAnchor, constant:2.5).isActive = true
        self.webView?.rightAnchor.constraint(equalTo: self.webViewContainer.rightAnchor, constant: 2.5).isActive = true
        self.webView?.topAnchor.constraint(equalTo: self.webViewContainer.topAnchor, constant: 5.0).isActive = true
        self.webView?.bottomAnchor.constraint(equalTo: self.webViewContainer.bottomAnchor).isActive = true
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if navigationAction.navigationType == .linkActivated {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            UIApplication.shared.open(url, options: [:]) { (success) in }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
