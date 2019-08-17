//
//  RTRSPage.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSPage: NSObject {

    let title: String
    let type: RTRSScreenType
    
    init(title: String, type: RTRSScreenType) {
        self.title = title
        self.type = type
    }
}
