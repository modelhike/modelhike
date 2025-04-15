//
//  StaticFolder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor StaticFolder : PersistableFolder {
    private let repo: InputFileRepository
    public let foldername: String
    public let newFoldername: String
    public private(set) var outputFolder: OutputFolder?
    let pInfo: ParsedInfo
    
    public func persist() async throws {
        if let ctx = pInfo.ctx as? GenerationContext {
            if let outputFolder {
                try await outputFolder.persist(with: ctx)
            } else {
                fatalError(#function + ": output path not set!")
            }
        } else {
            fatalError(#function + ": ctx is not GenerationContext")
        }
    }
    
    public func copyFiles() throws {
        if let outputFolder {
            try repo.copyFiles(foldername: foldername, to: outputFolder, with: pInfo)
        } else {
            fatalError(#function + ": output path not set!")
        }
    }
    
    public func outputFolder(baseFolder: LocalFolder) {
        outputFolder = OutputFolder(baseFolder / self.newFoldername)
    }
    
    public var debugDescription: String { get async {
        if let outputFolder {
            return await outputFolder.debugDescription + " : \(foldername) -> \(newFoldername)"
        } else {
            return "StaticFolder: \(foldername) -> \(newFoldername)"
        }
    }}
    
    public init(foldername: String, repo: InputFileRepository, to newFoldername:String, pInfo: ParsedInfo) {
        self.repo = repo
        self.foldername = foldername
        self.newFoldername = newFoldername
        self.outputFolder = nil
        self.pInfo = pInfo
    }
    
//    public init(foldername: String, repo: InputFileRepository, to newFoldername:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
//        self.repo = repo
//        self.foldername = foldername
//        self.newFoldername = newFoldername
//        self.outputFolder = OutputFolder(outFilePath / newFoldername)
//        self.pInfo = pInfo
//    }
    
}
