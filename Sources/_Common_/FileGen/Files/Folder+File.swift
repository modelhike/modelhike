//
//  Folder+ile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
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

    var files: [Fi] { get }
    var subFolders: [Fo] { get }
}

public protocol File: FileSystemItem {
    func readTextContents() throws -> String
    func readTextLines(ignoreEmptyLines: Bool) throws -> [String]
    func write(_ string: String) throws
    func write(_ string: String, encoding: String.Encoding) throws
}

public protocol FileSystemItem: Equatable, CustomStringConvertible {
    associatedtype Fo
    associatedtype Pa: Path

    var path: Pa { get }
    var parent: (Fo)? { get }
    var creationDate: Date? { get }
    var modificationDate: Date? { get }

    func move(to newPath: Fo) throws
    func delete() throws

    @discardableResult
    func copy(to folder: Fo) throws -> Self
}

extension FileSystemItem {
    public var pathString: String {
        let localPath = self.path
        return localPath.string
    }

    public var url: URL {
        let localPath = self.path
        return localPath.url
    }

    public var name: String {
        return url.pathComponents.last!
    }

    public var description: String {
        let typeName = String(describing: type(of: self))
        return "\(typeName)(name: \(name), path: \(path))"
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsPath = lhs.path
        let rhsPath = rhs.path
        return lhsPath.string == rhsPath.string
    }
}

extension File {
    public var nameExcludingExtension: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return name }
        return components.dropLast().joined(separator: ".")
    }

    public var `extension`: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return "" }
        return String(components.last ?? "")
    }

}

public struct FileDoesNotExist: ErrorWithMessage {
    let filename: String

    public var info: String {
        return "File does not exist: \(filename)"
    }

    public init(filename: String) {
        self.filename = filename
    }
}

public struct FolderDoesNotExist: ErrorWithMessage {
    let foldername: String

    public var info: String {
        return "Folder does not exist: \(foldername)"
    }

    public init(foldername: String) {
        self.foldername = foldername
    }
}
