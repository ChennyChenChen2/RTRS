//
//  RTRSNavigation.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import SwiftSoup

class RTRSNavigation {
    var doc: Document?
    
    init(html: String) {
        do {
            self.doc = try SwiftSoup.parse(html)
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
    }
    
    
    
}
