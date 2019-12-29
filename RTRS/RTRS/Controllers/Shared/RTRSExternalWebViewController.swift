//
//  RTRSExternalWebViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 11/1/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import WebKit

class RTRSExternalWebViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webViewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var webViewContainer: UIView!
    fileprivate let webView = WKWebView()
    var url: URL?
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = self.name
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        if let theUrl = self.url {
            self.webView.navigationDelegate = self
            self.webView.load(URLRequest(url: theUrl))
        }
        
        if !self.isBeingPresented {
            self.dismissButton.isHidden = true
            self.webViewContainerTopConstraint.constant = 0
        }
        
        self.webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.frame = self.view.frame
        self.webViewContainer.addSubview(self.webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        RTRSErrorHandler.showNetworkError(in: self) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

//        if navigationAction.navigationType == .linkActivated {
//            guard let url = navigationAction.request.url else {
//                decisionHandler(.cancel)
//                return
//            }
//
//            UIApplication.shared.open(url, options: [:]) { (success) in }
//            decisionHandler(.cancel)
//            return
//        }
        
        decisionHandler(.allow)
    }
}