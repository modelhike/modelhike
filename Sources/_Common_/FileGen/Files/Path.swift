//
//  Path.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Path: StringWrapper {
    var string: String {get}
    var url: URL {get}
    var name: String {get}
}

public struct LocalPath : Path, CustomDebugStringConvertible, Sendable {
    public static let separator = "/"
    
    public var string: String { url.path(percentEncoded: false) }
    public var url: URL

    public var name: String { url.lastPathComponent }
    
    public var exists: Bool {
        if isDirectory {
            var directory = ObjCBool(true)
            guard FileManager.default.fileExists(atPath: self.string, isDirectory: &directory) else {
                return false
            }
            return directory.boolValue
        } else {
            return FileManager.default.fileExists(atPath: self.string)
        }
    }

    @discardableResult
    public func ensureExists() throws -> Self {
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(
                atPath: string,
                withIntermediateDirectories: true
            )

        } catch {
            throw WriteError(path: string, reason: .folderCreationFailed(error))
        }
        
        return self
    }
    
    public var isDirectory: Bool {
        if let value = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, value {
            return true
        } else {
            return false
        }
    }

    public var isFile: Bool {
        if let value = try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, value {
            return true
        } else {
            return false
        }
    }

    public var isSymlink: Bool {
        do {
          let _ = try FileManager.default.destinationOfSymbolicLink(atPath: self.string)
          return true
        } catch {
          return false
        }
    }

    public var isReadable: Bool {
        return FileManager.default.isReadableFile(atPath: self.string)
    }

    public var isWritable: Bool {
        return FileManager.default.isWritableFile(atPath: self.string)
    }

    public var isExecutable: Bool {
        return FileManager.default.isExecutableFile(atPath: self.string)
    }

    public var isDeletable: Bool {
        return FileManager.default.isDeletableFile(atPath: self.string)
    }
    
    public func hardlink(to destination: LocalPath) throws -> () {
       try FileManager.default.linkItem(atPath: self.string, toPath: destination.string)
     }

    public func symlink(to destination: LocalPath) throws -> () {
       try FileManager.default.createSymbolicLink(atPath: destination.string, withDestinationPath: self.string)
     }
    
    public func symlinkDestination() throws -> LocalPath {
        let symlinkDestination = try FileManager.default.destinationOfSymbolicLink(atPath: string)
        let symlinkPath = LocalPath(symlinkDestination)
        return symlinkPath
    }
    
    public var debugDescription: String { string }
    
    public init(relativePath: String, basePath: String) {
        let baseURL = URL(filePath: basePath, directoryHint: .checkFileSystem)
        let combinedURL = baseURL.appendingPathComponent(relativePath)
        self.url = combinedURL.standardized
    }
    
    public init(relativePath: String, basePath: LocalPath) {
        let baseURL = basePath.url
        let combinedURL = baseURL.appendingPathComponent(relativePath)
        self.url = combinedURL.standardized
    }
    
    public init(_ string: String) {
        self.url = URL(filePath: string, directoryHint: .checkFileSystem)
    }
    
    public init(_ url: URL) {
        self.url = url
    }
}

public struct WebPath : Path, CustomDebugStringConvertible, Sendable {
    public static let root: WebPath = .init("/")
    public static let unknown: WebPath = .init("?")

    public var string: String { url.path(percentEncoded: false) }
    public var url: URL
    
    public var name: String { url.lastPathComponent }
    
    public var isAbsolute: Bool {
        return string.lowercased().hasPrefix("http://") || string.lowercased().hasPrefix("https://")
    }
    
    public func path(relativeTo basePath: WebPath) -> WebPath {
        let relativePath = url.path.replacingOccurrences(of: basePath.url.path, with: "")
        return WebPath(relativePath: relativePath, basePath: basePath)
    }
    
    public var debugDescription: String { string }

    public init(relativePath: String, basePath: WebPath) {
        let baseURL = basePath.url
        let combinedURL = baseURL.appendingPathComponent(relativePath)
        self.url = combinedURL.standardized
    }
    
    public init(_ string: String) {
        self.url = URL(string: string)!
        //self.string = string
    }
    
    public init(string: String) {
        self.url = URL(string: string)!
        //self.string = string
    }
    
    public init(url: URL) {
        self.url = url
        //self.string = url.path(percentEncoded: false)
    }
}

public extension LocalPath {
    @inlinable
    static func +(lhs: LocalPath, rhs: LocalPath) -> LocalPath {
        let url = lhs.url.appending(path: rhs.string)
        return LocalPath(url)
    }

    @inlinable
    static func +(lhs: LocalPath, rhs: any StringProtocol) -> LocalPath {
        let rhsString = String(rhs)
        if rhs.isEmpty || rhsString == "/" {
            return lhs
        } else {
            let url = lhs.url.appending(path: rhsString)
            return LocalPath(url)
        }
    }
    
    @inlinable
    static func /<S>(lhs: LocalPath, rhs: S) -> LocalPath where S: StringProtocol {
        let rhsString = String(rhs)
        if rhs.isEmpty || rhsString == "/" {
            return lhs
        } else {
            let url = lhs.url.appending(path: rhsString)
            return LocalPath(url)
        }
    }
}

public extension WebPath {
    @inlinable
    static func +(lhs: WebPath, rhs: WebPath) -> WebPath {
        let url = lhs.url.appending(path: rhs.string)
        return WebPath(url: url)
    }

    @inlinable
    static func +(lhs: WebPath, rhs: any StringProtocol) -> WebPath {
        let rhsString = String(rhs)
        if rhs.isEmpty || rhsString == "/" {
            return lhs
        } else {
            let url = lhs.url.appending(path: rhsString)
            return WebPath(url: url)
        }
    }
    
    @inlinable
    static func /<S>(lhs: WebPath, rhs: S) -> WebPath where S: StringProtocol {
        let rhsString = String(rhs)
        if rhs.isEmpty || rhsString == "/" {
            return lhs
        } else {
            let url = lhs.url.appending(path: rhsString)
            return WebPath(url: url)
        }
    }
}
