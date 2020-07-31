//
//  ArticleViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/8/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import WebKit

class ArticleViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    
    var dismissButton: UIButton?
    var saveButton: UIBarButtonItem!
    var viewModel: SingleArticleViewModel?
    var column: String?
    var webView: WKWebView?
    var webViewContentObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.viewModel != nil && self.column != nil, "View model and column cannot be nil")
        guard let vm = self.viewModel, let title = vm.title, let column = column else { return }
        AnalyticsUtils.logViewArticle(title, column: column)
        
        self.view.backgroundColor = .black
        self.scrollView.backgroundColor = .black
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        
        let button = UIBarButtonItem(image: RTRSPersistentStorage.contentIsAlreadySaved(vm: vm) ? #imageLiteral(resourceName: "Heart-Fill") : #imageLiteral(resourceName: "Heart-No-Fill"), style: .plain, target: self, action: #selector(saveAction))
        self.saveButton = button
        self.navigationItem.rightBarButtonItem = saveButton
        
        if let url = self.viewModel?.imageUrl {
            self.imageView.af.setImage(withURL: url)
        }
        
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
        
        if self.navigationController == nil || self.isBeingPresented {
            self.dismissButton = UIButton()
            self.dismissButton?.translatesAutoresizingMaskIntoConstraints = false
            self.dismissButton?.setImage(#imageLiteral(resourceName: "Dismiss-Icon"), for: .normal)
            
            self.dismissButton?.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
            self.view.addSubview(self.dismissButton!)
            self.scrollViewTopConstraint.constant = 50
        } else {
            self.scrollViewTopConstraint.constant = 0
        }
    }
    
    @objc func dismissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        self.webViewContentObservation = nil
    }
    
    override func viewWillLayoutSubviews() {
        self.dismissButton?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.dismissButton?.bottomAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: -10).isActive = true
                
        self.webView?.leftAnchor.constraint(equalTo: self.webViewContainer.leftAnchor, constant:2.5).isActive = true
        self.webView?.rightAnchor.constraint(equalTo: self.webViewContainer.rightAnchor, constant: 2.5).isActive = true
        self.webView?.topAnchor.constraint(equalTo: self.webViewContainer.topAnchor, constant: 5.0).isActive = true
        self.webView?.bottomAnchor.constraint(equalTo: self.webViewContainer.bottomAnchor).isActive = true
    }
    
    @objc func saveAction() {
        if let vm = self.viewModel {
            if RTRSPersistentStorage.contentIsAlreadySaved(vm: vm) {
                RTRSPersistentStorage.unsaveContent(vm)
                self.saveButton.image = #imageLiteral(resourceName: "Heart-No-Fill")
            } else {
                RTRSPersistentStorage.saveContent(vm)
                self.saveButton.image = #imageLiteral(resourceName: "Heart-Fill")
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if navigationAction.navigationType == .linkActivated {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
//            UIApplication.shared.open(url, options: [:]) { (success) in }
            RTRSExternalWebViewController.openExternalWebBrowser(self, url: url, name: url.absoluteString)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
