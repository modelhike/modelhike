//
// StaticFolder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class StaticFolder : PersistableFolder {
    private let repo: InputFileRepository
    public let foldername: String
    public private(set) var outputFolder: LocalFolder
    let pInfo: ParsedInfo
    
    public func persist() throws {
        try copyFiles()
    }
    
    public func copyFiles() throws {
        try repo.copyFiles(foldername: foldername, to: outputFolder, with: pInfo)
    }
    
    public init(foldername: String, repo: InputFileRepository, to newFoldername:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
        self.repo = repo
        self.foldername = foldername
        self.outputFolder = LocalFolder(path: outFilePath / newFoldername)
        self.pInfo = pInfo
    }
    
}
