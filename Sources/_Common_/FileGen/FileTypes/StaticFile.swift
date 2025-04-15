//
//  StaticFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct StaticFile : OutputFile {
    private let oldFilename: String
    public let filename: String

    private let repo: InputFileRepository?
    public var outputPath: LocalPath?
    let pInfo: ParsedInfo
    var contents: String? = nil
    var data: Data? = nil

    public mutating func render() throws {
        guard let repo = repo else { return }
        
        self.contents = try repo.readTextContents(filename: self.oldFilename, with: pInfo)
    }
    
    public func persist() throws {
        if let outputPath {
            if let contents = contents {
                let outFile = LocalFile(path: outputPath / filename)
                try outFile.write(contents)
            } else if let data = data {
                let outFile = LocalFile(path: outputPath / filename)
                try outFile.write(data)
            }
        } else {
            fatalError(#function + ": output path not set!")
        }
    }
    
    public var debugDescription: String {
        if let outputPath {
            let outFile = LocalFile(path: outputPath / filename)
            return outFile.pathString
        } else {
            return "StaticFile: \(filename)"
        }
    }
    
//    public init(filename: String, filePath: LocalPath, contents: String, pInfo: ParsedInfo) {
//        self.oldFilename = filename
//        self.filename = filename
//        self.outputPath = filePath
//        self.contents = contents
//        self.pInfo = pInfo
//        
//        self.data = nil
//        self.repo = nil
//    }
//    
//    public init(filename: String, filePath: LocalPath, data: Data, pInfo: ParsedInfo) {
//        self.oldFilename = filename
//        self.filename = filename
//        self.outputPath = filePath
//        self.contents = nil
//        self.data = data
//        self.pInfo = pInfo
//        
//        self.repo = nil
//    }
    
    public init(filename: String, contents: String, pInfo: ParsedInfo) {
        self.oldFilename = filename
        self.filename = filename
        self.outputPath = nil
        self.contents = contents
        self.pInfo = pInfo
        
        self.data = nil
        self.repo = nil
    }
    
    public init(filename: String, data: Data, pInfo: ParsedInfo) {
        self.oldFilename = filename
        self.filename = filename
        self.outputPath = nil
        self.contents = nil
        self.data = data
        self.pInfo = pInfo
        
        self.repo = nil
    }
    
    public init(filename: String, repo: InputFileRepository, to newFilename:String, pInfo: ParsedInfo) {
        self.oldFilename = filename
        self.filename = newFilename

        self.repo = repo
        self.outputPath = nil
        self.pInfo = pInfo
    }
    
//    public init(filename: String, repo: InputFileRepository, to newFilename:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
//        self.oldFilename = filename
//        self.filename = newFilename
//
//        self.repo = repo
//        self.outputPath = outFilePath
//        self.pInfo = pInfo
//    }
    
}
