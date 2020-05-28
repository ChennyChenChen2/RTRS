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
    
    class func saveContent(_ viewModel: SingleContentViewModel) {
        let codedData = NSKeyedArchiver.archivedData(withRootObject: viewModel)
        let type = RTRSScreenType.saved
        let path = getPathForType(type: type, specificName: viewModel.title)

        guard let thePath = path else { return }
        do {
            try codedData.write(to: thePath)
            NotificationCenter.default.post(name: .SavedContentUpdated, object: nil)
        } catch {
            print("Couldn't write to save file: " + error.localizedDescription)
        }
    }
    
    class func unsaveContent(_ viewModel: SingleContentViewModel) {
        let type = RTRSScreenType.saved
        let path = getPathForType(type: type, specificName: viewModel.title)

        guard let thePath = path else { return }
        do {
            try FileManager.default.removeItem(at: thePath)
            NotificationCenter.default.post(name: .SavedContentUpdated, object: nil)
        } catch {
            print("Couldn't unsave file: " + error.localizedDescription)
        }
    }
    
    class func removeAllSavedContent() {
        let type = RTRSScreenType.saved
        let path = getPathForType(type: type, specificName: nil)

        guard let thePath = path else { return }
        let pathURL = URL(fileURLWithPath: thePath.absoluteString)
        
        do {
            try FileManager.default.removeItem(at: pathURL)
            NotificationCenter.default.post(name: .SavedContentUpdated, object: nil)
        } catch {
            print("Couldn't unsave file: " + error.localizedDescription)
        }
    }
    
    class func contentIsAlreadySaved(vm: SingleContentViewModel) -> Bool {
        let content = getSavedContent()
        
        return content.contains { (vm2) -> Bool in
            if let title1 = vm.title, let title2 = vm2?.title {
                return title1 == title2
            } else {
                return false
            }
        }
    }
    
    class func getSavedContent() -> [SingleContentViewModel?] {
        var result = [SingleContentViewModel]()
        let type = RTRSScreenType.saved
        if let savedContentPath = getPathForType(type: type, specificName: nil),
            let paths = try? FileManager.default.contentsOfDirectory(atPath: savedContentPath.absoluteString) {
            
            for path in paths {
                let fullPathString = savedContentPath.absoluteString + "/\(path)"
                let fullPath = URL(fileURLWithPath: fullPathString)
                
                do {
                    if let codedData = try? Data(contentsOf: fullPath), let viewModel = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as? SingleContentViewModel {
                        result.append(viewModel)
                    }
                } catch {
                    print("Could not fetch saved content view model at path: \(path)")
                }
            }
        }
        
        return result
    }
    
    class func getViewModel(type: RTRSScreenType, specificName: String? = nil) -> RTRSViewModel? {
        var path: URL?
        if type == .pod || type == .auArticle || type == .normalColumnArticle {
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
            case .about, .advertise, .au, .normalColumn, .contact, .events, .home, .lotteryParty, .more, .newsletter, .podSource, .podcasts, .processPups, .shirts, .subscribe:
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
                    if !FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
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
            case .normalColumnArticle:
                let dirPath = storageDir.appendingPathComponent("NormalColumn", isDirectory: true)
                var isDir : ObjCBool = false
                
                do {
                    if !FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
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
                    if !FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
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
            case .saved:
                let dirPath = storageDir.appendingPathComponent("saved", isDirectory: true)
                var isDir : ObjCBool = true
                
                do {
                    if !FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory:&isDir) {
                        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
                        if let theSpecificName = specificName {
                            let escapedSpecificName = theSpecificName.replacingOccurrences(of: "/", with: ":")
                            let fullPath = dirPath.appendingPathComponent("\(escapedSpecificName).rtrs")
                            if !FileManager.default.fileExists(atPath: fullPath.absoluteString) {
                                FileManager.default.createFile(atPath: fullPath.absoluteString, contents: nil, attributes: nil)
                            }
                            return fullPath
                        } else {
                            return URL(string: dirPath.absoluteString.replacingOccurrences(of: "file://", with: "")) ?? dirPath
                        }
                    }
                } catch let error {
                    print("ERROR SAVING SAVED CONTENT: \(error.localizedDescription)")
                }
                
                return dirPath
            }
        
        return nil
    }
}

extension Notification.Name {
    static let SavedContentUpdated = Notification.Name("SavedContentUpdated")
}
