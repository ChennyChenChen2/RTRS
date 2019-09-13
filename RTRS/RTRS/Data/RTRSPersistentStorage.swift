//
//  RTRSPersistentStorage.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSPersistentStorage: NSObject {

    /*
     DIR STRUCTURE:
     - Top level:
        - Home.rtrs
        - About.rtrs
        - Podcasts
            - PodcastTitle1.rtrs
            - PodcastTitle2.rtrs
        - AUCorner
            - AUTitle1.rtrs
            - AUTitle2.rtrs
 */
    static let storageDir: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryURL = paths.first!.appendingPathComponent("Ricky")
        do {
            try FileManager.default.createDirectory(at: documentsDirectoryURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("Couldn't create directory")
        }
        
        return documentsDirectoryURL
    }()
    
    class func save(viewModel: RTRSViewModel, type: RTRSScreenType) {
        let codedData = NSKeyedArchiver.archivedData(withRootObject: viewModel)
        var path: URL?
        if type == .pod || type == .auArticle {
            path = getPathForType(type: type, specificName: viewModel.pageName())
        } else {
            path = getPathForType(type: type)
        }

        guard let thePath = path else { return }
        do {
            try codedData.write(to: thePath)
        } catch {
            print("Couldn't write to save file: " + error.localizedDescription)
        }
    }
    
    class func getViewModel(type: RTRSScreenType, specificName: String? = nil) -> RTRSViewModel? {
        var path: URL?
        if type == .pod || type == .auArticle {
            path = getPathForType(type: type, specificName: specificName)
        } else {
            path = getPathForType(type: type)
        }
        
        guard let thePath = path, let codedData = try? Data(contentsOf: thePath) else { return nil }
        
        do {
            if let viewModel = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as? RTRSViewModel {
                return viewModel
            }
        } catch {
            print("Could not fetch view model for type: \(type.rawValue) and specificName: \(specificName ?? "EMPTY")")
        }
        
        return nil
    }
    
    private class func getPathForType(type: RTRSScreenType, specificName: String? = nil) -> URL? {
        switch type {
        case .about, .advertise, .au, .contact, .events, .home, .lotteryParty, .more, .newsletter, .podcasts, .processPups, .shirts, .subscribe:
            do {
                let fullPath = storageDir.appendingPathComponent("\(type.rawValue).rtrs")
                if !FileManager.default.fileExists(atPath: fullPath.absoluteString) {
                    FileManager.default.createFile(atPath: fullPath.absoluteString, contents: nil, attributes: nil)
                }
                return fullPath
            }

        case .auArticle:
            let dirPath = storageDir.appendingPathComponent("AUArticles", isDirectory: true)
            var isDir : ObjCBool = false
            do {
                if FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
                    try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
                }
                
                if let theSpecificName = specificName {
                    let fullPath = dirPath.appendingPathComponent("\(theSpecificName).rtrs")
                    if !FileManager.default.fileExists(atPath: fullPath.absoluteString) {
                        FileManager.default.createFile(atPath: fullPath.absoluteString, contents: nil, attributes: nil)
                    }
                    return fullPath
                }
            } catch {
                print("Couldn't create directory for screen type: \(type.rawValue)")
            }
            break
        case .pod:
            let dirPath = storageDir.appendingPathComponent("Pods", isDirectory: true)
            var isDir : ObjCBool = false
            do {
                if FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
                    try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
                }
                
                if let theSpecificName = specificName {
                    let fullPath = dirPath.appendingPathComponent("\(theSpecificName).rtrs")
                    if !FileManager.default.fileExists(atPath: fullPath.absoluteString) {
                        FileManager.default.createFile(atPath: fullPath.absoluteString, contents: nil, attributes: nil)
                    }
                    return fullPath
                }
            } catch {
                print("Couldn't create directory for screen type: \(type.rawValue)")
            }
            break
        }
        
        return nil
    }
}
