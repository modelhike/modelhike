//
// StaticFolder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class StaticFolder  {
    private let repo: InputFileRepository
    private let foldername: String
    public var outputFolder: LocalFolder

//    public func persist() throws {
//        try inputFolder.copy(to: outputFolder)
//    }
    
    public func copyFiles() throws {
        try repo.copyFiles(foldername: foldername, to: outputFolder)
    }
    
    public init(foldername: String, repo: InputFileRepository, to newFoldername:String, path outFilePath: LocalPath) {
        self.repo = repo
        self.foldername = foldername
        self.outputFolder = LocalFolder(path: outFilePath / newFoldername)
    }
    
}
