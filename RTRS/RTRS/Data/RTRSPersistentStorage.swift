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
        var path: NSURL?
        if type == .pod || type == .auArticle || type == .normalColumnArticle {
            path = getPathForType(type: type, specificName: viewModel.pageName())
        } else {
            path = getPathForType(type: type)
        }

        guard let thePath = path else { return }
        do {
            try codedData.write(to: thePath as URL)
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
            try codedData.write(to: thePath as URL)
            NotificationCenter.default.post(name: .SavedContentUpdated, object: nil)
        } catch {
            print("Couldn't write to save file: " + error.localizedDescription)
        }
        
        if let title = viewModel.title {
            AnalyticsUtils.logSavedContent(title)
        }
    }
    
    class func unsaveContent(_ viewModel: SingleContentViewModel) {
        let type = RTRSScreenType.saved
        let path = getPathForType(type: type, specificName: viewModel.title)

        guard let thePath = path else { return }
        do {
            try FileManager.default.removeItem(at: thePath as URL)
            NotificationCenter.default.post(name: .SavedContentUpdated, object: nil)
        } catch {
            print("Couldn't unsave file: " + error.localizedDescription)
        }
    }
    
    class func removeAllSavedContent() {
        let type = RTRSScreenType.saved
        let path = getPathForType(type: type, specificName: nil)

        guard let thePath = path, let pathString = thePath.absoluteString else { return }
        let pathURL = URL(fileURLWithPath: pathString)
        
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
    
    class func updateArticle(articleVM: SingleArticleViewModel, column: RTRSScreenType) {
        guard let multiArticleVM = getViewModel(type: column) as? MultiArticleViewModel else { return }
        let index = multiArticleVM.content.firstIndex { (contentVM) -> Bool in
            guard let compareArticleVM = contentVM as? SingleArticleViewModel else { return false }
            return compareArticleVM.title == articleVM.title
        }
        
        if let index = index {
            multiArticleVM.content[index] = articleVM
            RTRSPersistentStorage.save(viewModel: multiArticleVM, type: column)
        }
    }
    
    // Naively add pod VM and corresponding URL to beginning of multi pod VM and pod source.
    // Hope that on the next force reload, they will be sorted correctly and duplicates will be dealt with.
    class func addPod(podVM: RTRSSinglePodViewModel, podInfo: PodInfo) {
        guard let multiPodVM = getViewModel(type: .podcasts) as? RTRSMultiPodViewModel, let sourceVM = getViewModel(type: .podSource) as? RTRSPodSourceViewModel else { return }
        multiPodVM.content.insert(podVM, at: 0)
        multiPodVM.resortPods()
        
        sourceVM.podInfo.insert(podInfo, at: 0)
        sourceVM.resortPodInfo()
        
        RTRSNavigation.shared.registerViewModel(viewModel: multiPodVM, for: .podcasts)
        RTRSNavigation.shared.registerViewModel(viewModel: sourceVM, for: .podSource)
        NotificationCenter.default.post(name: Notification.Name.podLoadedNotificationName, object: nil)
    }
    
    class func getSavedContent() -> [SingleContentViewModel?] {
        var result = [SingleContentViewModel]()
        let type = RTRSScreenType.saved
        if let savedContentPath = getPathForType(type: type, specificName: nil), let pathString = savedContentPath.absoluteString,
            let paths = try? FileManager.default.contentsOfDirectory(atPath: pathString) {
            
            for path in paths {
                let fullPathString = pathString + "/\(path)"
                let fullPath = NSURL(fileURLWithPath: fullPathString)
                
                do {
                    if let codedData = try? Data(contentsOf: fullPath as URL), let viewModel = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as? SingleContentViewModel {
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
        var path: NSURL?
        if type == .pod || type == .auArticle || type == .normalColumnArticle {
            path = getPathForType(type: type, specificName: specificName)
        } else {
            path = getPathForType(type: type)
        }
        
        guard let thePath = path, let codedData = try? Data(contentsOf: thePath as URL) else { return nil }
        
        do {
            if let viewModel = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as? RTRSViewModel {
                return viewModel
            } else {
                print("Couldn't unarchive viewModel?")
            }
        } catch {
            print("Could not fetch view model for type: \(type.rawValue) and specificName: \(specificName ?? "EMPTY")")
        }
        
        return nil
    }
    
    private class func getPathForType(type: RTRSScreenType, specificName: String? = nil) -> NSURL? {
            switch type {
            case .about, .au, .normalColumn, .moc, .contact, .events, .home, .lotteryParty, .more, .newsletter, .podSource, .podcasts, .processPups, .abbie, .goodDogClub, .shirts, .sponsors, .subscribe:
                do {
                    let pathComponent = "\(type.rawValue).rtrs"
                    let path = pathComponent.replacingOccurrences(of: " ", with: "")
                    
                    let fullPath = storageDir.appendingPathComponent(path)
                    if !FileManager.default.fileExists(atPath: fullPath.absoluteString) {
                        FileManager.default.createFile(atPath: fullPath.absoluteString, contents: nil, attributes: nil)
                    }
                    return fullPath as NSURL
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
                        return fullPath as NSURL
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
                        return fullPath as NSURL
                    }
                } catch {
                    print("Couldn't create directory for screen type: \(type.rawValue)")
                }
                break
            case .mocArticle:
                let dirPath = storageDir.appendingPathComponent("MOC", isDirectory: true)
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
                        return fullPath as NSURL
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
                        return fullPath as NSURL
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
                            return fullPath as NSURL
                        } else {
                            return NSURL(string: dirPath.absoluteString.replacingOccurrences(of: "file://", with: "")) ?? dirPath as NSURL
                        }
                    }
                } catch let error {
                    print("ERROR SAVING SAVED CONTENT: \(error.localizedDescription)")
                }
                
                return dirPath as NSURL
            }
        
        return nil
    }
}

extension Notification.Name {
    static let SavedContentUpdated = Notification.Name("SavedContentUpdated")
}
