//
//  RTRSNavigation.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import SwiftSoup
import WebKit

enum RTRSScreens {
    case home
    case about
    case podcasts
    case au
    case newsletter
    case subscribe
    case processPups
    case shirts
    case events(String) // Event name param
    case lotteryParty
    case contact
    case advertise
    
//    var urlSuffix: String {
//        switch self {
//
//        }
//    }
}

class RTRSNavigation: NSObject, WKUIDelegate {
    fileprivate var doc: Document?
    fileprivate var webView: WKWebView!
    
    override init() {
        super.init()
        
    }
    
    init(html: String) {
        super.init()
        do {
            self.doc = try SwiftSoup.parse(html)
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        print("HERE!")
    }
    
    fileprivate func fetchLatestHtml() {
        let url = URL(string: "https://www.rightstorickysanchez.com")!
        let myRequest = URLRequest(url: url)
        self.webView.load(myRequest)
    }
}
