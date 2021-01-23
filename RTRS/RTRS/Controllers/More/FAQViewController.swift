//
//  FAQViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/28/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import Foundation
import UIKit

class FAQViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = AppStyles.foregroundColor
        self.navigationController?.navigationBar.barTintColor = AppStyles.backgroundColor
        self.view.backgroundColor = AppStyles.backgroundColor
        
        self.contentTextView.backgroundColor = AppStyles.backgroundColor
        self.contentTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: AppStyles.foregroundColor, NSAttributedString.Key.font: Font.bodyFont, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        
        self.titleLabel.textColor = AppStyles.foregroundColor
        self.contentTextView.textColor = AppStyles.foregroundColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsUtils.logScreenView("FAQ")
    }
}
