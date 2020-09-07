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
    case normalColumn = "Sixers Adam Normal Column"
    case normalColumnArticle = "Normal Column Article"
    case moc = "The Good O'Connor (Mike)"
    case mocArticle = "MOC Article"
    case auArticle = "AU Article"
    case newsletter = "The Corner Three Newsletter"
    case subscribe = "Subscribe"
    case processPups = "Process Pups"
    case goodDogClub = "By Nature Good Boy Good Girl Club"
    case abbie = "Abbie's Art Gallery"
    case shirts = "T-Shirt Store"
    case events = "Events"
    case lotteryParty = "Lottery Party"
    case contact = "Contact"
    case advertise = "Advertise"
    case more = "More"
    case saved = "Saved"
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
