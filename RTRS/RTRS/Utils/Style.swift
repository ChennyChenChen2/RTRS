//
//  Style.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/2/20.
//  Copyright © 2020 Jonathan Chen. All rights reserved.
//

import UIKit

enum AppStyles {
    
    static var darkModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: AppSettings.darkModeUserDefaultsKey)
    }
    
    static var backgroundColor: UIColor {
        return darkModeEnabled ? .black : .white
    }
    
    static var foregroundColor: UIColor {
        return darkModeEnabled ? .white : .black
    }
    
    static var settingsIcon: UIImage {
        return darkModeEnabled ? #imageLiteral(resourceName: "Settings-light") : #imageLiteral(resourceName: "Settings-dark")
    }
    
    static var dogStuffIcon: UIImage {
        return darkModeEnabled ? #imageLiteral(resourceName: "Dog-Stuff-Light") : #imageLiteral(resourceName: "Dog-Stuff-Dark")
    }
    
    static var mailIcon: UIImage {
        return darkModeEnabled ? #imageLiteral(resourceName: "Mail-Light") : #imageLiteral(resourceName: "Mail-Dark")
    }
    
    static var shareIcon: UIImage {
        return darkModeEnabled ? #imageLiteral(resourceName: "Share-Light") : #imageLiteral(resourceName: "Share-Dark")
    }
    
    private static var likeIconUnfilled: UIImage {
        return darkModeEnabled ? #imageLiteral(resourceName: "Heart-No-Fill-Light") : #imageLiteral(resourceName: "Heart-No-Fill-Dark")
    }
    
    private static var likeIconFilled: UIImage {
        return #imageLiteral(resourceName: "Heart-Fill")
    }
    
    static func likeIcon(for viewModel: SingleContentViewModel) -> UIImage {
        return RTRSPersistentStorage.contentIsAlreadySaved(vm: viewModel) ? AppStyles.likeIconFilled : AppStyles.likeIconUnfilled
    }
}

enum TextSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var size: Double {
        switch self {
        case .small: return 1.25
        case .medium: return 1.5
        case .large: return 2.0
        }
    }
}

enum Font {
    static let textSizeDefaultsKey = "textSizeKey"
    private static let titleMetrics = UIFontMetrics(forTextStyle: .subheadline)
    private static let bodyMetrics = UIFontMetrics(forTextStyle: .footnote)
    private static let captionMetrics = UIFontMetrics(forTextStyle: .caption2)
    
    static var cellTitleFont: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline).withFamily("Trebuchet MS").withSymbolicTraits(.traitBold)!
        let font = UIFont(descriptor: descriptor, size: 15)
        return titleMetrics.scaledFont(for: font)
    }
    
    static var bodyFont: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote).withFamily("Trebuchet MS")
        let font = UIFont(descriptor: descriptor, size: 12)
        return bodyMetrics.scaledFont(for: font)
    }
    
    static var captionFont: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2).withFamily("Trebuchet MS")
        let font = UIFont(descriptor: descriptor, size: 10)
        return captionMetrics.scaledFont(for: font)
    }
    
    static func presentTextSizeSheet(in vc: UIViewController, completion: (()->())?) {
        let sizes: [TextSize] = TextSize.allCases
        
        let optionMenu = UIAlertController(title: nil, message: "Choose Font Size", preferredStyle: .actionSheet)
           
        for size in sizes {
            let action = UIAlertAction(title: size.rawValue, style: .default) { (action) in
                guard let title = action.title, let size = TextSize(rawValue: title) else { return }
                UserDefaults.standard.set(size.size, forKey: self.textSizeDefaultsKey)
                AnalyticsUtils.logTextSizeChange(size.rawValue)
                completion?()
            }
            
            optionMenu.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        optionMenu.addAction(cancelAction)
               
        vc.present(optionMenu, animated: true)
    }
}
