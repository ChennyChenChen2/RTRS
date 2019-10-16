//
//  PodcastManager.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class PodcastManager: NSObject {

    static let shared = PodcastManager()
    override private init() {}
    fileprivate let viewModel = RTRSNavigation.shared.viewModel(for: .podSource)
    
    func preparePlayer() {
        
    }
    
    func requestPod(url: URL) {
        
    }
}
