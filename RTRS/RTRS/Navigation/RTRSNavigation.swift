//
//  RTRSNavigation.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import SwiftSoup

enum RTRSScreenType: String, Hashable {
    case home = "Home"
    case about = "About"
    case podcasts = "The Pod"
    case pod = "A Pod"
    case au = "If Not, Pick Will Convey As Two Second-Rounders"
    case auArticle = "AU Article"
    case newsletter = "Newsletter"
    case subscribe = "Subscribe"
    case processPups = "Process Pups"
    case shirts = "T-Shirt Store"
    case events = "Events"
    case lotteryParty = "Lottery Party"
    case contact = "Contact"
    case advertise = "Advertise"
    case more = "More"    
}

class RTRSNavigation: NSObject {
    public static let shared = RTRSNavigation()
    override private init() {}
    
    fileprivate var pages = [RTRSScreenType: RTRSViewModel]()
    
    func registerViewModel(viewModel: RTRSViewModel, for page: RTRSScreenType) {
        pages[page] = viewModel
    }
    
    func viewModel(for page: RTRSScreenType) -> RTRSViewModel? {
        return pages[page]
    }
}
