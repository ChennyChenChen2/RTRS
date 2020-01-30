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
    
    private static let podCompletion: (URL, RTRSNavigationController) -> () = { (url, navController) in
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
                            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
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
    
    
    static func route(payload: RTRSDeepLinkPayload, navController: RTRSNavigationController, shouldOpenExternalWebBrowser: Bool) {
        let url = payload.baseURL
        
        func openExternalWebBrowser() {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "RTRSExternalWebViewController") as! RTRSExternalWebViewController
            vc.name = payload.title
            vc.url = payload.baseURL
            navController.present(vc, animated: true, completion: nil)
        }
        
        if shouldOpenExternalWebBrowser {
            openExternalWebBrowser()
        }
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        if url.absoluteString.contains("bit.ly") {
            makeBitlyRequest(url, navController: navController, payload: payload)
        } else if url.path.contains("podcast") {
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
        } else if url.path.contains("if-not-will-convey-as-two-second-rounders") {
            if let vm = RTRSNavigation.shared.viewModel(for: .au) as? MultiArticleViewModel {
                let articles = vm.content.filter({ (vm) -> Bool in
                    guard let articleVm = vm as? SingleArticleViewModel, let articleUrl = articleVm.baseURL else { return false }
                    let vmPath = articleUrl.lastPathComponent
                    let urlPath = url.lastPathComponent
                    
                    return vmPath == urlPath
                })
                
                if articles.count > 0, let article = articles.first as? SingleArticleViewModel {
                    DispatchQueue.main.async {
                        let vc = storyboard.instantiateViewController(withIdentifier: "SingleArticle") as! AUCornerArticleViewController
                        vc.viewModel = article
                        
                        navController.present(vc, animated: true
                            , completion: nil)
                    }
                }
            }
        } else if url.path.contains("normal-column") {
            if let vm = RTRSNavigation.shared.viewModel(for: .normalColumn) as? MultiArticleViewModel {
                let articles = vm.content.filter({ (vm) -> Bool in
                    guard let articleVm = vm as? SingleArticleViewModel, let articleUrl = articleVm.baseURL else { return false }
                    let vmPath = articleUrl.lastPathComponent
                    let urlPath = url.lastPathComponent
                    
                    return vmPath == urlPath
                })
                
                if articles.count > 0, let article = articles.first as? SingleArticleViewModel {
                    DispatchQueue.main.async {
                        let vc = storyboard.instantiateViewController(withIdentifier: "SingleArticle") as! AUCornerArticleViewController
                        vc.viewModel = article
                        
                        navController.present(vc, animated: true
                            , completion: nil)
                    }
                }
            }
        } else {
            openExternalWebBrowser()
        }
    }
    
    fileprivate static func makeBitlyRequest(_ url: URL, navController: RTRSNavigationController, payload: RTRSDeepLinkPayload) {
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
                                let newPayload = RTRSDeepLinkPayload(baseURL: longUrl, title: payload.title)
                                RTRSDeepLinkHandler.route(payload: newPayload, navController: navController, shouldOpenExternalWebBrowser: false)
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
