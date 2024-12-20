//
// StaticFile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class StaticFile : OutputFile {
    private let oldFilename: String
    public let filename: String

    private let repo: InputFileRepository
    public var outputPath: LocalPath!
    let pInfo: ParsedInfo
    public func persist() throws {
        let contents = try repo.readTextContents(filename: self.oldFilename, pInfo: pInfo)

        let outFile = LocalFile(path: outputPath / filename)
        try outFile.write(contents)
    }
    
    public init(filename: String, repo: InputFileRepository, to newFilename:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
        self.oldFilename = filename
        self.filename = newFilename

        self.repo = repo
        self.outputPath = outFilePath
        self.pInfo = pInfo
    }
    
}
