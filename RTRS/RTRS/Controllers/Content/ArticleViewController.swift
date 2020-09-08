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
    var textSizeButton: UIBarButtonItem!
    var shareButton: UIBarButtonItem!
    var viewModel: SingleArticleViewModel?
    var column: String?
    var webView: WKWebView?
    var webViewContentObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.viewModel != nil && self.column != nil, "View model and column cannot be nil")
        guard let vm = self.viewModel, let title = vm.title, let column = column else { return }
        AnalyticsUtils.logViewArticle(title, column: column)
        
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        
        let saveButton = UIBarButtonItem(image: AppStyles.likeIcon(for: vm), style: .plain, target: self, action: #selector(saveAction))
        self.saveButton = saveButton
        
        let textSizeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "TextSize-Dark"), style: .plain, target: self, action: #selector(textSizeChangeAction))
        self.textSizeButton = textSizeButton
        
        let shareButton = UIBarButtonItem(image: AppStyles.shareIcon, style: .plain, target: self, action: #selector(shareAction))
        self.shareButton = shareButton
        
        self.navigationItem.rightBarButtonItems = [shareButton, saveButton, textSizeButton]
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = AppStyles.backgroundColor
        self.webViewContainer.backgroundColor = AppStyles.backgroundColor
        self.scrollView.backgroundColor = AppStyles.backgroundColor
        
        self.dismissButton?.tintColor = AppStyles.foregroundColor
        self.textSizeButton.tintColor = AppStyles.foregroundColor
        self.shareButton.tintColor = AppStyles.foregroundColor
        
        if let vm = self.viewModel {
            self.saveButton.image = AppStyles.likeIcon(for: vm)
        }
        
        self.titleLabel.textColor = AppStyles.foregroundColor
        self.titleLabel.backgroundColor = AppStyles.backgroundColor
        self.titleLabel.layer.borderColor = AppStyles.foregroundColor.cgColor
        self.titleLabel.layer.backgroundColor = AppStyles.backgroundColor.cgColor
        
        if UserDefaults.standard.double(forKey: Font.textSizeDefaultsKey) == 0 {
            UserDefaults.standard.set(TextSize.medium.size, forKey: Font.textSizeDefaultsKey)
        }
        
        self.loadContent()
    }
    
    private func htmlWithCSS(_ templateHTML: String) -> String {
        let cssPlaceholder = "{{CSS_PLACEHOLDER}}"
        var cssString = ""
        
        if let path = Bundle.main.path(forResource: "RTRS", ofType: "css"), let cssFileContents = try? String(contentsOfFile: path) {
            let fontSizePlaceholder = "{{FONT_SIZE_PLACEHOLDER}}"
            let fontSize = "\(UserDefaults.standard.double(forKey: Font.textSizeDefaultsKey))"
            var css = cssFileContents.replacingOccurrences(of: fontSizePlaceholder, with: fontSize)
            
            let bgColorPlaceholder = "{{BG_COLOR_PLACEHOLDER}}"
            let bgColor = AppStyles.darkModeEnabled ? "black" : "white"
            css = css.replacingOccurrences(of: bgColorPlaceholder, with: bgColor)
            
            let fontColorPlaceholder = "{{FONT_COLOR_PLACEHOLDER}}"
            let fontColor = AppStyles.darkModeEnabled ? "white" : "black"
            css = css.replacingOccurrences(of: fontColorPlaceholder, with: fontColor)
            
            cssString = css
        } else {
            // This is our fault...
            print("Cannot find RTRS.css")
        }
        
        return templateHTML.replacingOccurrences(of: cssPlaceholder, with: cssString)
    }
    
    private func loadContent() {
        if let htmlString = self.viewModel?.htmlString, let baseURL = self.viewModel?.baseURL {
            let htmlPlusCSS = htmlWithCSS(htmlString)
            self.webView?.loadHTMLString(htmlPlusCSS, baseURL: baseURL)
        }
    }
    
    @objc private func shareAction() {
        guard let url = viewModel?.baseURL else { return }

       // set up activity view controller
       let itemToShare = [ url ]
       let activityViewController = UIActivityViewController(activityItems: itemToShare, applicationActivities: nil)
       activityViewController.popoverPresentationController?.sourceView = self.view

       // present the view controller
       self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc private func contentSizeDidChange(_ obj: Any) {
        self.loadContent()
    }
    
    @objc func dismissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            } else {
                RTRSPersistentStorage.saveContent(vm)
            }
            
            self.saveButton.image = AppStyles.likeIcon(for: vm)
        }
    }
    
    @objc func textSizeChangeAction() {
        Font.presentTextSizeSheet(in: self) {
            self.loadContent()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if navigationAction.navigationType == .linkActivated {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            RTRSExternalWebViewController.openExternalWebBrowser(self, url: url, name: url.absoluteString)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
