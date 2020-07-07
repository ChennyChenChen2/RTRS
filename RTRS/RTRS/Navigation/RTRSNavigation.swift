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
    case podSource = "Pod Source"
    case au = "If Not, Pick Will Convey As Two Second-Rounders"
    case normalColumn = "Sixers Adam: Normal Column"
    case normalColumnArticle = "Normal Column Article"
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
    case saved = "Saved"
    
    var rawValue: String {
        switch self {
        case .home:
            return "Home"
        case .about:
            return "About"
        case .podcasts:
            return "The Pod"
        case .pod:
            return "A Pod"
        case .podSource:
            return "Pod Source"
        case .au:
            return "If Not, Pick Will Convey As Two Second-Rounders"
        case .normalColumn:
            return "Sixers Adam: Normal Column"
        case .normalColumnArticle:
            return "Normal Column Article"
        case .auArticle:
            return "AU Article"
        case .newsletter:
            return "Newsletter"
        case .subscribe:
            return "Subscribe"
        case .processPups:
            return "Process Pups"
        case .shirts:
            return "T-Shirt Store"
        case .events:
            return "Events"
        case .lotteryParty:
            return "Lottery Party"
        case .contact:
            return "Contact"
        case .advertise:
            return "Advertise"
        case .more:
            return "More"
        case .saved:
            return "Saved"
        }
    }
}

class RTRSNavigation: NSObject {
    public static let shared = RTRSNavigation()
    override private init() {}
    
    fileprivate var pages = [RTRSScreenType: RTRSViewModel]()
    
    func registerViewModel(viewModel: RTRSViewModel, for page: RTRSScreenType) {
        self.pages[page] = viewModel
        RTRSPersistentStorage.save(viewModel: viewModel, type: page)
    }
    
    func viewModel(for page: RTRSScreenType) -> RTRSViewModel? {
        if let vm = pages[page] {
            return vm
        } else {
            let vm = RTRSPersistentStorage.getViewModel(type: page)
            pages[page] = vm
            return vm
        }
    }
}
