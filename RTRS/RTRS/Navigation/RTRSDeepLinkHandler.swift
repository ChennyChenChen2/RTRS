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
            let completion: (URL) -> () = { (url) in
                do {
                    let htmlString = try String.init(contentsOf: url)
                    let document = try SwiftSoup.parse(htmlString)
                    let h1Elems = try document.getElementsByTag("h1")
                    let titleElems = h1Elems.filter { (element) -> Bool in
                        return element.hasClass("title") || element.hasClass("entry-title")
                    }
                    
                    if let titleElem = titleElems.first,
                        let text = try? titleElem.text(),
                        let vm = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel {
                        let filteredVms = vm.content.filter { (vm) -> Bool in
                            guard let theVm = vm as? RTRSSinglePodViewModel, let title = theVm.title else { return false }
                            return title == text
                        }
                        
                        DispatchQueue.main.async {
                            if let podVM = filteredVms.first as? RTRSSinglePodViewModel {
                                 var vc: PodcastPlayerViewController!
                                if let theVC = PodcastManager.shared.currentPodVC, let podTitle = podVM.title, let currentPodTitle = PodcastManager.shared.title, podTitle == currentPodTitle {
                                     vc = theVC
                                 } else {
                                    vc = (storyboard.instantiateViewController(withIdentifier: "PodcastPlayer") as! PodcastPlayerViewController)
                                     vc.viewModel = podVM
                                     PodcastManager.shared.currentPodVC = vc
                                 }
                                
                                navController.present(vc, animated: true, completion: nil)
                            }
                        }
                    }
                } catch {
                    RTRSErrorHandler.showNetworkError(in: navController, completion: nil)
                    return
                }
            }
            
            if url.path.contains("podcast") {
                completion(url)
            } else if url.absoluteString.contains("bit.ly") {
                makeBitlyRequest(url, navController: navController, completion: completion)
            }
        } else if url.path.contains("if-not-will-convey-as-two-second-rounders") {
            if let vm = RTRSNavigation.shared.viewModel(for: .au) as? MultiArticleViewModel {
                let articles = vm.content.filter({ (vm) -> Bool in
                    guard let articleVm = vm as? SingleArticleViewModel, let articleUrl = articleVm.baseURL else { return false }
                    return articleUrl == url
                })
                
                if articles.count > 0, let article = articles.first as? SingleArticleViewModel {
                    
                    let vc = storyboard.instantiateViewController(withIdentifier: "AUSingleArticle") as! AUCornerArticleViewController
                    vc.viewModel = article
                    
                    navController.present(vc, animated: true
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
    
    fileprivate static func makeBitlyRequest(_ url: URL, navController: RTRSNavigationController, completion: @escaping (URL) -> ()) {
        let requestUrlString = "https://api-ssl.bitly.com/v3/expand?access_token=f7916216fac500f0cd358971fddb8399330ddb9f&shortUrl=\(url.absoluteString)"
        if let requestUrl = URL(string: requestUrlString) {
            URLSession.shared.dataTask(with: requestUrl) { (data, response, error) in
                if error == nil {
                    if let unwrappedData = data,
                        let theData = try? JSONSerialization.jsonObject(with: unwrappedData, options: .allowFragments) as?  [String: Any],
                        let dataDict = theData["data"] as? [String: [Any]],
                        let expandArray = dataDict["expand"] {
                        if expandArray.count > 0 {
                            if let expandDict = expandArray[0] as? [String: Any],
                            let longUrlString = expandDict["long_url"] as? String,
                                let longUrl = URL(string: longUrlString) {
                                completion(longUrl)
                            }
                        }
                    }
                } else {
                    // TODO: Refactor out error handling stuff
                    RTRSErrorHandler.showNetworkError(in: navController, completion: nil)
                }
            }.resume()
        }
        
    }
    
    fileprivate static func routeArticle(payload: RTRSDeepLinkPayload) {
        
    }
    
    fileprivate static func routePod(payload: RTRSDeepLinkPayload) {
        
    }
    
}
