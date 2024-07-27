//
// SystemFolder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum SystemFolder {
    
}

public extension SystemFolder {
    static var current: LocalFolder {
        let folderString = FileManager.default.currentDirectoryPath
        return LocalFolder(path: folderString)
    }

    static var library: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .libraryDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }
    
    static var documents: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }

    static var cache: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }
    
    static var desktop: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .desktopDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }
    
    static var downloads: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .downloadsDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }
    
    static var developerResources: LocalFolder {
        let folderURL = try! FileManager.default.url(
                    for: .developerDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
        
        return LocalFolder(path: folderURL)
    }
    
    static var temporary: LocalFolder {
        return LocalFolder(path: NSTemporaryDirectory())
    }
}
