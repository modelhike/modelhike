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
    
    public func renderFiles() throws {
        try templateSoup.repo.renderFiles(foldername: foldername, to: outputFolder, using: templateSoup)
    }
    
    public init(foldername: String, templateSoup: TemplateSoup, to newFoldername:String, path outFilePath: LocalPath) {
        self.templateSoup = templateSoup
        self.foldername = foldername
        self.outputFolder = LocalFolder(path: outFilePath / newFoldername)
    }
    
}
