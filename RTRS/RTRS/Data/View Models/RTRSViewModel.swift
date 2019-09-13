//
//  RTRSViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/26/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import SwiftSoup

protocol RTRSViewModel: NSCoding {
    func extractDataFromDoc(doc: Document?, urls: [URL]?)
    func pageName() -> String
    func pageImage() -> UIImage
}
