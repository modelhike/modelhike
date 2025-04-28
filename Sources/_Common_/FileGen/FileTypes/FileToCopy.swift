//
//  FileToCopy.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor FileToCopy : CopyableFile {
    
    public var filename: String { outFile.filename }
    public let outFile: LocalFile

    let pInfo: ParsedInfo
    
    public private(set) var outputPath: LocalPath?

    public func outputPath(_ path: LocalPath) {
        self.outputPath = path
    }
    
    public func persist() throws {
        if let outputPath {
            try outFile.copy(to: outputPath)
        } else {
            fatalError(#function + ": output path not set!")
        }
    }
     
    public var debugDescription: String {
        return outFile.pathString
    }
    
    public init(file: LocalFile, pInfo: ParsedInfo) {
        self.outFile = file

        self.outputPath = nil
        self.pInfo = pInfo
    }
    
//    public init(file: LocalFile, toPath: LocalPath, pInfo: ParsedInfo) {
//        self.outFile = file
//
//        self.outputPath = toPath
//        self.pInfo = pInfo
//    }
}
