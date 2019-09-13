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
    let type: RTRSScreenType
    
    init(baseURL: URL, title: String, type: RTRSScreenType) {
        self.baseURL = baseURL
        self.title = title
        self.type = type
    }
}

class RTRSDeepLinkHandler: NSObject {
    
    static func route(payload: RTRSDeepLinkPayload, navController: RTRSNavigationController) {
        let url = payload.baseURL
        var vc: UIViewController?
        if url.path.contains("podcast") {
            
        } else if url.path.contains("if-not-will-convey-as-two-second-rounders") {
            
        }
    }
    
    fileprivate static func routeArticle(payload: RTRSDeepLinkPayload) {
        
    }
    
    fileprivate static func routePod(payload: RTRSDeepLinkPayload) {
        
    }
    
}
