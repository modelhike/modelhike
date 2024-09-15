//
// Folder+ile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Folder: FileSystemItem {
    associatedtype Fo
    associatedtype Fi
    func ensureExists() throws -> Self
    func createTextFile(named fileName: String, contents: String) throws -> Fi
    func readTextFile(named fileName: String) throws -> String
    
    func isEmpty() throws -> Bool
    func deleteAllFilesAndFolders() throws
    
    func fileExists(_ path: String) -> Bool
    func subfolderExists(_ path: String) -> Bool
    func subfolder(at folderPath: String) throws -> Self
    
    var files : [Fi] {get}
    var subFolders : [Fo] {get}
}


public protocol File: FileSystemItem {
    func readTextContents() throws -> String
    func readTextLines(ignoreEmptyLines: Bool) throws -> [String]
    func write(_ string: String) throws
    func write(_ string: String, encoding: String.Encoding) throws
}

public protocol FileSystemItem: Equatable, CustomStringConvertible {
    associatedtype Fo
    associatedtype Pa : Path
    
    var path: Pa { get }
    var parent: (Fo)? { get}
    var creationDate: Date? { get }
    var modificationDate: Date? { get }
    
    func move(to newPath: Fo) throws
    func delete() throws
    
    @discardableResult
    func copy(to folder: Fo) throws -> Self
}

public extension FileSystemItem {
    var pathString: String {
        let localPath = self.path
        return localPath.string
    }

    var url: URL {
        let localPath = self.path
        return localPath.url
    }

    var name: String {
        return url.pathComponents.last!
    }
    
    var description: String {
        let typeName = String(describing: type(of: self))
        return "\(typeName)(name: \(name), path: \(path))"
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        let lhsPath = lhs.path
        let rhsPath = rhs.path
        return lhsPath.string == rhsPath.string
    }
}

public extension File {
    var nameExcludingExtension: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return name }
        return components.dropLast().joined(separator: ".")
    }

    var `extension`: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return "" }
        return String(components.last ?? "")
    }
    
}

public struct FileDoesNotExist : Error {
    let filename: String
    
    public init(filename: String) {
        self.filename = filename
    }
}

public struct FolderDoesNotExist : Error {
    let foldername: String
    
    public init(foldername: String) {
        self.foldername = foldername
    }
}
