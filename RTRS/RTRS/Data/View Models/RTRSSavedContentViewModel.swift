//
//  RTRSSavedContentViewModel.swift
//  RTRS
//
//  Created by Jonathan Chen on 11/22/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import SwiftSoup

class RTRSSavedContentViewModel: NSObject, RTRSViewModel, MultiContentViewModel {
    func extractDataFromDoc(doc: Document?, urls: [URL]?) {
        // Empty implementation
    }
    
    func pageName() -> String {
        return "Saved"
    }
    
    func pageImage() -> UIImage {
        return #imageLiteral(resourceName: "Roco")
    }
    
    func pageUrl() -> URL? {
        return nil
    }
    
    func loadedNotificationName() -> Notification.Name? {
        return nil
    }
    
    func encode(with coder: NSCoder) {
        // empty implementation
    }
    
    required init?(coder: NSCoder) {
        // Empty impl
    }
    
    var content: [SingleContentViewModel?] {
        return RTRSPersistentStorage.getSavedContent()
    }
    
    override init() {
        super.init()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateSavedContent), name: .SavedContentUpdated, object: nil)
    }
}
