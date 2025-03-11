//
//  StaticFolder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class StaticFolder : PersistableFolder {
    private let repo: InputFileRepository
    public let foldername: String
    public private(set) var outputFolder: OutputFolder
    let pInfo: ParsedInfo
    
    public func persist() throws {
        if let ctx = pInfo.ctx as? GenerationContext {
            try outputFolder.persist(with: ctx)
        } else {
            fatalError(#function + ": ctx is not GenerationContext")
        }
    }
    
    public func copyFiles() throws {
        try repo.copyFiles(foldername: foldername, to: outputFolder, with: pInfo)
    }
    
    public init(foldername: String, repo: InputFileRepository, to newFoldername:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
        self.repo = repo
        self.foldername = foldername
        self.outputFolder = OutputFolder(outFilePath / newFoldername)
        self.pInfo = pInfo
    }
    
}
