//
//  RTRSDeepLinkHandler.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/12/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

struct RTRSDeepLinkPayload {
    let baseURL: URL
    let title: String
    
    init(baseURL: URL, title: String) {
        self.baseURL = baseURL
        self.title = title
    }
}

class RTRSDeepLinkHandler: NSObject {
    
    static func route(payload: RTRSDeepLinkPayload, navController: RTRSNavigationController) {
        let url = payload.baseURL
        var vc: UIViewController?
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        if url.path.contains("podcast") {
            let vm = RTRSNavigation.shared.viewModel(for: .podcasts)
            
            
        } else if url.path.contains("if-not-will-convey-as-two-second-rounders") {
            if let vm = RTRSNavigation.shared.viewModel(for: .au) as? AUCornerMultiArticleViewModel {
                let articles = vm.content.filter({ (vm) -> Bool in
                    guard let articleVm = vm as? AUCornerSingleArticleViewModel, let articleUrl = articleVm.baseURL else { return false }
                    return articleUrl == url
                })
                
                if articles.count > 0, let article = articles.first as? AUCornerSingleArticleViewModel {
                    
                    let vc = storyboard.instantiateViewController(withIdentifier: "AUSingleArticle") as! AUCornerArticleViewController
                    vc.viewModel = article
                    
                    navController.present(AUCornerArticleViewController(), animated: true
                        , completion: nil)
                }
            }
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "RTRSExternalWebViewController") as! RTRSExternalWebViewController
            vc.name = payload.title
            vc.url = payload.baseURL
            navController.present(vc, animated: true, completion: nil)
        }
    }
    
    fileprivate static func routeArticle(payload: RTRSDeepLinkPayload) {
        
    }
    
    fileprivate static func routePod(payload: RTRSDeepLinkPayload) {
        
    }
    
}
