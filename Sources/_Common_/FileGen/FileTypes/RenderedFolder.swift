//
//  RenderedFolder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class RenderedFolder : PersistableFolder {
    private let templateSoup: TemplateSoup
    public let foldername: String
    public private(set) var outputFolder: LocalFolder
    let pInfo: ParsedInfo
    
    public func persist() throws {
        try renderFiles()
    }
    
    public func renderFiles() throws {
        try templateSoup.repo.renderFiles(foldername: foldername, to: outputFolder, using: templateSoup, with: pInfo)
    }
    
    public init(foldername: String, templateSoup: TemplateSoup, to newFoldername:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
        self.templateSoup = templateSoup
        self.foldername = foldername
        self.outputFolder = LocalFolder(path: outFilePath / newFoldername)
        self.pInfo = pInfo
    }
    
}
