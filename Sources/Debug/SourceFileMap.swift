//
//  SourceFileMap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor SourceFileMap {
    private var files: [String: SourceFile] = [:]

    public func register(identifier: String, content: String, fullPath: String?, fileType: SourceFileType) {
        let file = SourceFile(
            identifier: identifier,
            fullPath: fullPath,
            content: content,
            fileType: fileType
        )
        files[identifier] = file
    }

    public func file(for identifier: String) -> SourceFile? {
        files[identifier]
    }

    public func allFiles() -> [SourceFile] {
        Array(files.values)
    }
}



// MARK: - Source Location

public struct SourceLocation: Codable, Sendable, Equatable {
    public let fileIdentifier: String
    public let lineNo: Int
    public let lineContent: String
    public let level: Int

    public init(fileIdentifier: String, lineNo: Int, lineContent: String, level: Int = 0) {
        self.fileIdentifier = fileIdentifier
        self.lineNo = lineNo
        self.lineContent = lineContent
        self.level = level
    }
}

// MARK: - Source File

public struct SourceFile: Codable, Sendable {
    public let identifier: String
    public let fullPath: String?
    public let content: String
    public let lineCount: Int
    public let fileType: SourceFileType

    public init(identifier: String, fullPath: String?, content: String, fileType: SourceFileType) {
        self.identifier = identifier
        self.fullPath = fullPath
        self.content = content
        self.lineCount = content.components(separatedBy: .newlines).count
        self.fileType = fileType
    }
}

public enum SourceFileType: String, Codable, Sendable {
    case soupyScript
    case template
    case model
    case config
}
