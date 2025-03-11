//
//  FileToCopy.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class FileToCopy : CopyableFile {
    public var outputPath: LocalPath!
    
    public var filename: String { outFile.filename }
    
    public let outFile: LocalFile

    let pInfo: ParsedInfo
    
    public func persist() throws {
        try outFile.copy(to: outputPath)
    }
    
    public init(file: LocalFile, toPath: LocalPath, pInfo: ParsedInfo) {
        self.outFile = file

        self.outputPath = toPath
        self.pInfo = pInfo
    }
    
    
}
