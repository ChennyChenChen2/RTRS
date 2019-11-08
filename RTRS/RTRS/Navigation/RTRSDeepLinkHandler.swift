//
//  RTRSDeepLinkHandler.swift
//  RTRS
//
//  Created by Jonathan Chen on 9/12/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

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
        
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            
            if url.path.contains("podcast") || url.absoluteString.contains("bit.ly") {
                do {
                    let document = Document(url.absoluteString)
                    let h1Elems = try document.getElementsByTag("h1")
                    let titleElems = h1Elems.filter { (element) -> Bool in
                        return element.hasClass("title")
                    }
                    if let titleElem = titleElems.first {
                        let text = try titleElem.text()
                        let vm = RTRSNavigation.shared.viewModel(for: .podcasts) as! RTRSMultiPodViewModel
                        let filteredVms = vm.content.filter { (vm) -> Bool in
                            guard let theVm = vm as? RTRSSinglePodViewModel, let title = theVm.title else { return false }
                            return title == text
                        }
                        
                        if let podVM = filteredVms.first as? RTRSSinglePodViewModel {
                            let vc = storyboard.instantiateViewController(withIdentifier: "PodcastPlayer") as! PodcastPlayerViewController
                            vc.viewModel = podVM
                            navController.present(vc, animated: true, completion: nil)
                        }
                    }
                } catch {
                    return
                }
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
