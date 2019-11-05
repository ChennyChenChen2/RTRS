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
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.frame = self.view.frame
        self.webViewContainer.addSubview(self.webView)
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
