//
// RenderedFolder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class RenderedFolder  {
    private let templateSoup: TemplateSoup
    private let foldername: String
    public var outputFolder: LocalFolder
    let pInfo: ParsedInfo
    
    public func renderFiles() throws {
        try templateSoup.repo.renderFiles(foldername: foldername, to: outputFolder, using: templateSoup, pInfo: pInfo)
    }
    
    public init(foldername: String, templateSoup: TemplateSoup, to newFoldername:String, path outFilePath: LocalPath, pInfo: ParsedInfo) {
        self.templateSoup = templateSoup
        self.foldername = foldername
        self.outputFolder = LocalFolder(path: outFilePath / newFoldername)
        self.pInfo = pInfo
    }
    
}
