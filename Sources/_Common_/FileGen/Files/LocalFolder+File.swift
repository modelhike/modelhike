//
//  LocalFolder+File.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct LocalFolder : Folder, LocalFileSystemItem {
    public var path: LocalPath
    
    @discardableResult
    public func ensureExists() throws -> Self {
        try path.ensureExists()
        return self
    }
    
    public var exists : Bool {
        return path.exists
    }
    
    public func fileExists(_ path: String) -> Bool {
        let url = URL(filePath: path)
        if let keys = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]) {
            
            if let _ = keys.isRegularFile {
                return true
            }
        }
        
        return false
//        var isFolder: ObjCBool = false
//
//        let fileManager = FileManager.default
//        guard fileManager.fileExists(atPath: path, isDirectory: &isFolder) else {
//            return false
//        }
//
//        return true
    }
    
    public func subfolderExists(_ path: String) -> Bool {
        let url = URL(filePath: path)
        if let keys = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]) {
            
            if let _ = keys.isDirectory {
                return true
            }
        }
        
        return false
//        var isFolder: ObjCBool = true
//
//        let fileManager = FileManager.default
//        guard fileManager.fileExists(atPath: path, isDirectory: &isFolder) else {
//            return false
//        }
//
//        return true
    }
    
    public func subfolder(at folderPath: String) -> Self {
        let folderPath = url.appending(path: folderPath.removingPrefix("/"))
        return LocalFolder(path: folderPath)
    }
    
    public func createTextFile(named fileName: String, contents: String) throws -> LocalFile {
        let filePath = url.appending(path: fileName).path(percentEncoded: false)

        do {
            try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
            return LocalFile(path: filePath)
        }
        catch {
            throw WriteError(path: filePath, reason: .fileCreationFailed)
        }
    }
    
    public func readTextFile(named fileName: String) throws -> String {
        let filePath = url.appending(path: fileName).path(percentEncoded: false)

        do {
            let stringContent = try String(contentsOfFile: filePath, encoding: .utf8)
            return stringContent
        }
        catch {
            throw ReadError(path: filePath, reason: .readFailed(error))
        }
    }
    
    public var files : [LocalFile] {
        var files: [LocalFile] = []
        let fm = FileManager.default

        do {
            let items = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

            for item in items {
                if let keys = try? item.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]) {

                    if let isFile = keys.isRegularFile, isFile {
                        files.append(LocalFile(path: item))
                    } else if let _ = keys.isDirectory {
                        // nothing for now
                    } else if let isLink = keys.isSymbolicLink, isLink {
                        files.append(LocalFile(path: item.resolvingSymlinksInPath()))
                    }
                }
            }
        } catch {
            //throw ReadError(path: path, reason: .readFailed(error))
            return []
        }
        
        return files
    }
    
    public var subFolders : [LocalFolder] {
        var folders: [LocalFolder] = []
        let fm = FileManager.default

        do {
            let items = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

            for item in items {
                if let keys = try? item.resourceValues(forKeys: [.isDirectoryKey]) {

                    if let isDir = keys.isDirectory, isDir {
                        folders.append(LocalFolder(path: item))
                    }
                }
            }
        } catch {
            //throw ReadError(path: path, reason: .readFailed(error))
            return []
        }
        
        return folders
    }
    
    @discardableResult
    public func copyFiles(to folder: LocalFolder) throws -> Self {
        try folder.ensureExists()
        
        let newPathString = folder.path.string
        
        let files = self.files
        
        for file in files {
            try file.copy(to: folder)
        }
        
        //copy files from subfolders also
        for subFolder in self.subFolders {
            let newFolder = folder / subFolder.name
            try newFolder.ensureExists()
            try subFolder.copyFiles(to: newFolder)
        }
        
        return Self(path: newPathString)
    }
    
    @discardableResult
    public func copy(to folder: LocalFolder) throws -> Self {
        let newPathString = folder.path.string
        
        do {
            try FileManager.default.copyItem(atPath: pathString, toPath: newPathString)
        } catch {
            throw LocationError(path: path, reason: .copyFailed(error))
        }
        
        return Self(path: newPathString)
    }
    
    public func deleteAllFilesAndFolders() throws {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        do {
            for item in items {
                try fileManager.removeItem(atPath: item.path(percentEncoded: false))
            }
        } catch {
            throw LocationError(path: path, reason: .deleteFailed(error))
        }
    }
    
    public func isEmpty() throws -> Bool {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return items.count == 0
    }
    
    public init(relativePath: String, basePath: String) {
        self.path = LocalPath(relativePath: relativePath, basePath: basePath)
    }
    
    public init(relativePath: String, basePath: LocalFolder) {
        self.path = LocalPath(relativePath: relativePath, basePath: basePath.path)
    }
    
    public init(path value: String) {
        self.path = LocalPath(value)
    }
    
    public init(path value: URL) {
        self.path = LocalPath(value)
    }
    
    public init(path value: LocalPath) {
        self.path = value
    }
}

public struct LocalFile : File, LocalFileSystemItem {
    public var path: LocalPath
    
    public func readTextContents() throws -> String {
        let filePath = pathString //.removingPrefix("/")

        do {
            let stringContent = try String(contentsOfFile: filePath, encoding: .utf8)
            return stringContent
        }
        catch {
            throw ReadError(path: filePath, reason: .readFailed(error))
        }
    }
    
    public func readTextLines(ignoreEmptyLines: Bool) throws -> [String] {
        let filePath = pathString //.removingPrefix("/")

        do {
            let contents = try readTextContents()
            let lines = contents.splitIntoLines()
            return lines
        }
        catch {
            throw ReadError(path: filePath, reason: .readFailed(error))
        }
    }
    
    public func write(_ data: Data) throws {
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw WriteError(path: path, reason: .writeFailed(error))
        }
    }
    
    public func write(_ string: String) throws {
        try write(string, encoding: .utf8)
    }
    
    public func write(_ string: String, encoding: String.Encoding) throws {
        do {
            try string.write(to: url, atomically: true, encoding: encoding)
        } catch {
            throw WriteError(path: path, reason: .writeFailed(error))
        }
    }
    
    @discardableResult
    public func copy(to folder: LocalFolder) throws -> Self {
        let newPathString = (folder.path / name).string
        
        do {
            try FileManager.default.copyItem(atPath: pathString, toPath: newPathString)
        } catch {
            throw LocationError(path: path, reason: .copyFailed(error))
        }
        
        return Self(path: newPathString)
    }
    
    @discardableResult
    public func copyFile(to outFile: LocalFile) throws -> LocalFile {
        let contents = try self.readTextContents()
        try outFile.write(contents)
        return outFile
    }
    
    public var exists:  Bool { path.exists }
    
    public init(relativePath: String, basePath: String) {
        self.path = LocalPath(relativePath: relativePath, basePath: basePath)
    }
    
    public init(relativePath: String, basePath: LocalPath) {
        self.path = LocalPath(relativePath: relativePath, basePath: basePath)
    }
    
    public init(path value: String) {
        self.path = LocalPath(value)
    }
    
    public init(path value: URL) {
        self.path = LocalPath(value)
    }
    
    public init(path value: LocalPath) {
        self.path = value
    }
}

public protocol LocalFileSystemItem : FileSystemItem where Pa == LocalPath, Fo == LocalFolder {
    //associatedtype Fo
    var pathString: String { get }
    var url: URL { get }
    var name: String { get }
    init(path value: String)
}

public extension LocalFileSystemItem {
    
    var parent: (LocalFolder)? {
        guard path.string != "/" else { return nil }
        
        let components = url.pathComponents.dropLast()
        if !components.isEmpty {
            let parentPath = components.joined(separator: "/") + "/"
            return LocalFolder(path: parentPath)
        } else {
            return LocalFolder(path: "/")
        }
    }

    var creationDate: Date? {
        return attributes[.creationDate] as? Date
    }

    var modificationDate: Date? {
        return attributes[.modificationDate] as? Date
    }
    
    private var attributes: [FileAttributeKey : Any] {
        let fileManager = FileManager.default
        let localPath = path
        return (try? fileManager.attributesOfItem(atPath: localPath.string)) ?? [:]
    }
    
    func move(to newPath: Fo) throws {
        do {
            try FileManager.default.moveItem(atPath: pathString, toPath: newPath.pathString)
        } catch {
            throw LocationError(path: path, reason: .moveFailed(error))
        }
    }

    func delete() throws {
        do {
            try FileManager.default.removeItem(atPath: pathString)
        } catch {
            throw LocationError(path: path, reason: .deleteFailed(error))
        }
    }
    
    func hardlink(to destination: Pa) throws -> () {
       try FileManager.default.linkItem(atPath: self.pathString, toPath: destination.string)
     }

    func symlink(to destination: Pa) throws -> () {
       try FileManager.default.createSymbolicLink(atPath: self.pathString, withDestinationPath: destination.string)
     }
    
}

public extension Array where Element == any LocalFileSystemItem {
    func move(to newPath: LocalFolder) throws {
        _ = try self.map({ try $0.move(to: newPath)})
    }
    
    func copy(to newPath: LocalFolder) throws  {
        _ = try self.map({ try $0.copy(to: newPath)})
    }
    
    func delete() throws {
        _ = try self.map({ try $0.delete()})
    }
}

public extension LocalFolder {
    @inlinable
    static func +(lhs: LocalFolder, rhs: LocalFolder) -> LocalFolder {
        let url = lhs.url.appending(path: rhs.pathString)
        return LocalFolder(path: url)
    }

    @inlinable
    static func +(lhs: LocalFolder, rhs: any StringProtocol) -> LocalFolder {
        let url = lhs.url.appending(path: String(rhs))
        return LocalFolder(path: url)
    }
    
    @inlinable
    static func /<S>(lhs: Self, rhs: S) -> LocalFolder where S: StringProtocol {
        return lhs + rhs
    }
}
