//
//  KeyValueObserver.swift
//  RTRS
//
//  Created by Jonathan Chen on 10/22/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

// Usually this would be declared as a static var on the class, but Swift does not support abstract static vars... yet
fileprivate var KVOContext: UInt8 = 0

/// Wrapper class for KVO. Swift KVO is a bit buggy with enums so far...
class KeyValueObserver<ObserveeType: AnyObject>: NSObject {
    
    typealias KeyValueObservationClosure = (_ object: ObserveeType, _ change: [NSKeyValueChangeKey : Any]?) -> Void
    
    fileprivate var keyPaths = Set<String>()
    fileprivate var closures = [String: KeyValueObservationClosure]()
    
    fileprivate weak var observeeObject: NSObject?
    fileprivate(set) weak var observee: ObserveeType?
    
    init(observee: ObserveeType) {
        guard let observeeObject = observee as? NSObject else {
            fatalError("cannot KVO non-NSObject")
        }
        
        self.observeeObject = observeeObject
        self.observee = observee
    }
    
    deinit {
        guard let observeeObject = self.observeeObject else {
            assertionFailure("failed to remove observers before deinit")
            return
        }
        
        self.keyPaths.forEach({ observeeObject.removeObserver(self, forKeyPath: $0, context: &KVOContext) })
    }
    
    func addObserver(forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], closure: @escaping KeyValueObservationClosure) {
        self.closures[keyPath] = closure
        self.keyPaths.insert(keyPath)
        self.observeeObject?.addObserver(self, forKeyPath: keyPath, options: options, context: &KVOContext)
    }
    
    func removeObserver(forKeyPath keyPath: String) {
        self.observeeObject?.removeObserver(self, forKeyPath: keyPath, context: &KVOContext)
        self.keyPaths.remove(keyPath)
        self.closures.removeValue(forKey: keyPath)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &KVOContext {
            guard let keyPath = keyPath else {
                return
            }
            
            guard let object = object as? ObserveeType else {
                assertionFailure("failed to typecast object... this should never happen")
                return
            }
            
            if let closure = self.closures[keyPath] {
                closure(object, change)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

}
