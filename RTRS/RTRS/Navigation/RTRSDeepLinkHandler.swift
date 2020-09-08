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
    let podURLString: String?
    let sharingURLString: String?
    
    init(baseURL: URL, title: String, podURLString: String?, sharingURLString: String?) {
        self.baseURL = baseURL
        self.title = title
        self.podURLString = podURLString
        self.sharingURLString = sharingURLString
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
            RTRSErrorHandler.showError(in: navController, type: .network, completion: nil)
            return
        }
    }
    
    
    static func route(payload: RTRSDeepLinkPayload, navController: RTRSNavigationController, shouldOpenExternalWebBrowser: Bool) {
        let url = payload.baseURL
        
        if shouldOpenExternalWebBrowser {
            RTRSExternalWebViewController.openExternalWebBrowser(navController, url: payload.baseURL, name: payload.title)
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
                
                let dateElem = try document.getElementsByClass("published")
                let imgElem = try document.getElementsByClass("thumb-image")
                let descriptionElem = try document.select("meta[property=og:description]")
                
                if let titleElem = titleElems.first,
                    let text = try? titleElem.text(),
                    let date = try? dateElem.first()?.text(),
                    let description = try? descriptionElem.first()?.attr("content"),
                    let imgUrlString = try? imgElem.first()?.attr("data-src"),
                    let imgUrl = URL(string: imgUrlString),
                    let vm = RTRSNavigation.shared.viewModel(for: .podcasts) as? RTRSMultiPodViewModel {
                    let filteredVms = vm.content.filter { (vm) -> Bool in
                        guard let theVm = vm as? RTRSSinglePodViewModel, let title = theVm.title else { return false }
                        return title == text
                    }
                    
                    if let podVM = filteredVms.first as? RTRSSinglePodViewModel {
                        if let theVC = PodcastManager.shared.currentPodVC,
                           let podTitle = podVM.title,
                           let currentPodTitle = PodcastManager.shared.title, podTitle == currentPodTitle {
                            DispatchQueue.main.async {
                                navController.present(theVC, animated: true, completion: nil)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let vc = (storyboard.instantiateViewController(withIdentifier: "PodcastPlayer") as! PodcastPlayerViewController)
                                vc.viewModel = podVM
                                PodcastManager.shared.currentPodVC = vc
                                navController.present(vc, animated: true, completion: nil)
                            }
                        }
                    } else {
                        guard let podSourceVM = RTRSNavigation.shared.viewModel(for: .podSource) as? RTRSPodSourceViewModel, let podURLString = payload.podURLString, let podURL = URL(string: podURLString) else { return }
                        
                        let podVM = RTRSSinglePodViewModel(title: text, date: date, description: description, imageURL: imgUrl, sharingUrl: podURL)
                        vm.content.insert(podVM, at: 0)
                        RTRSPersistentStorage.save(viewModel: podVM, type: .podcasts)
                        
                        if !podSourceVM.podUrls.contains(podURL) {
                            podSourceVM.podUrls.insert(podURL, at: 0)
                            RTRSPersistentStorage.save(viewModel: podSourceVM, type: .podSource)
                        }
                        
                        let vc = (storyboard.instantiateViewController(withIdentifier: "PodcastPlayer") as! PodcastPlayerViewController)
                        vc.viewModel = podVM
                        PodcastManager.shared.currentPodVC = vc
                        
                        DispatchQueue.main.async {
                            navController.dismiss(animated: true, completion: nil)
                            navController.present(vc, animated: true, completion: nil)
                        }
                    }
                } else {
                    RTRSErrorHandler.showError(in: navController, type: .dataNotAvailable, completion: nil)
                }
            } catch {
                RTRSErrorHandler.showError(in: navController, type: .network, completion: nil)
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
                        let vc = storyboard.instantiateViewController(withIdentifier: "SingleArticle") as! ArticleViewController
                        vc.viewModel = article
                        vc.column = "AU"
                        
                        navController.present(vc, animated: true
                            , completion: nil)
                    }
                } else {
                    RTRSExternalWebViewController.openExternalWebBrowser(navController, url: payload.baseURL, name: payload.title)
                }
            } else {
                RTRSErrorHandler.showError(in: navController, type: .dataNotAvailable, completion: nil)
            }
        } else if url.path.contains("the-good-oconnor-mike") {
            if let vm = RTRSNavigation.shared.viewModel(for: .moc) as? MultiArticleViewModel {
                let articles = vm.content.filter({ (vm) -> Bool in
                    guard let articleVm = vm as? SingleArticleViewModel, let articleUrl = articleVm.baseURL else { return false }
                    let vmPath = articleUrl.lastPathComponent
                    let urlPath = url.lastPathComponent
                    
                    return vmPath == urlPath
                })
                
                if articles.count > 0, let article = articles.first as? SingleArticleViewModel {
                    DispatchQueue.main.async {
                        let vc = storyboard.instantiateViewController(withIdentifier: "SingleArticle") as! ArticleViewController
                        vc.viewModel = article
                        vc.column = "The Good O'Connor (Mike)"
                        
                        navController.present(vc, animated: true
                            , completion: nil)
                    }
                } else {
                    RTRSExternalWebViewController.openExternalWebBrowser(navController, url: payload.baseURL, name: payload.title)
                }
            } else {
                RTRSErrorHandler.showError(in: navController, type: .dataNotAvailable, completion: nil)
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
                        let vc = storyboard.instantiateViewController(withIdentifier: "SingleArticle") as! ArticleViewController
                        vc.viewModel = article
                        vc.column = "Normal Column"
                        
                        navController.present(vc, animated: true
                            , completion: nil)
                    }
                } else {
                    RTRSExternalWebViewController.openExternalWebBrowser(navController, url: payload.baseURL, name: payload.title)
                }
            } else {
                RTRSErrorHandler.showError(in: navController, type: .dataNotAvailable, completion: nil)
            }
        } else {
            RTRSExternalWebViewController.openExternalWebBrowser(navController, url: payload.baseURL, name: payload.title)
        }
    }
    
    fileprivate static func makeBitlyRequest(_ url: URL, navController: RTRSNavigationController, payload: RTRSDeepLinkPayload) {
        let requestUrlString = "https://api-ssl.bitly.com/v4/expand"
        let bodyData = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let body = ["bitlink_id": bodyData]
        if let requestUrl = URL(string: requestUrlString),
            let token = Bundle.main.object(forInfoDictionaryKey: "BitlyAccessToken") as? String,
            let jsonData = try? JSONSerialization.data(withJSONObject: body) {
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error == nil {
                    if let unwrappedData = data,
                        let theData = try? JSONSerialization.jsonObject(with: unwrappedData, options: .allowFragments) as?  [String: Any],
                        let longUrlString = theData["long_url"] as? String,
                        let longUrl = URL(string: longUrlString) {
                        let newPayload = RTRSDeepLinkPayload(baseURL: longUrl, title: payload.title, podURLString: payload.podURLString, sharingURLString: payload.sharingURLString)
                        RTRSDeepLinkHandler.route(payload: newPayload, navController: navController, shouldOpenExternalWebBrowser: false)
                    }
                } else {
                    // TODO: Refactor out error handling stuff
                    RTRSErrorHandler.showError(in: navController, type: .network, completion: nil)
                }
            }.resume()
        }
        
    }
    
    fileprivate static func routeArticle(payload: RTRSDeepLinkPayload) {
        
    }
    
    fileprivate static func routePod(payload: RTRSDeepLinkPayload) {
        
    }
    
}
