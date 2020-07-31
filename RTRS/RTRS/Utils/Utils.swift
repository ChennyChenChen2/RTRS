//
//  Utils.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import SwiftSoup
import Atributika

class RTRSUserDefaultsKeys {
    static let lastUpdated = "RickyLastUpdated"
    static let htmlStorage = "RickyHTMLStorage"
    static let configStorage = "RickyConfig"
}

class Utils {
    static let defaultFont = UIFont(name: "TrebuchetMS", size: 14)!
    static let defaultFontBold = UIFont(name: "TrebuchetMS-Bold", size: 14)!
}

extension NSAttributedString {
    
    /*
 <p><strong>The Rights To Ricky Sanchez</strong> is a podcast that is sort-of about the Sixers and is hosted by Spike Eskin and Michael Levin. It is the only known podcast about the Sixers.&nbsp;</p>
     
     <p>Spike Eskin is one of the hosts of The Rights To Ricky Sanchez. He works in radio in Philadelphia. You can follow him on Twitter <strong><a target="_blank" href="http://www.twitter.com/spikeeskin">@SpikeEskin</a>.</strong></p>
     
     <p>Michael Levin is one of the hosts of The Rights To Ricky Sanchez. He works in television in Los Angeles. You can find him on Twitter <a target="_blank" href="http://www.twitter.com/michael_levin"><strong>@Michael_Levin</strong></a>.&nbsp;</p>
     
     <p>Kristen runs the Rights To Ricky Sanchez Twitter and Facebook pages, as well as being an associate producer of the podcast. She also monitors our listener email.</p>
     */
    
    static func attributedStringFrom(element: Element) -> NSAttributedString {
        let html = element.description
        guard let data = html.data(using: .utf8, allowLossyConversion: false) else { return NSAttributedString(string: html) }
        
        let attrString = try! NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        return attrString
    }
}
