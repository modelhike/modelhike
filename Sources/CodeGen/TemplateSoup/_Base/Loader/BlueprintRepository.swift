//
// TemplateRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol BlueprintRepository : InputFileRepository {
    var blueprintName: String {get}
    func blueprintExists() -> Bool
    func loadTemplate(fileName: String) throws -> TemplateSoupTemplate
}

public protocol InputFileRepository {
    func copyFiles(foldername: String, to folder: LocalFolder) throws
    func renderFiles(foldername: String, to folder: LocalFolder, using templateSoup: TemplateSoup) throws

    func readTextContents(filename: String) throws -> String
    func hasFolder(_ foldername: String) -> Bool
}

public struct TemplateDoesNotExist : Error {
    let templateName: String
    
    public init(templateName: String) {
        self.templateName = templateName
    }
}

public struct TemplateReadingError: Error {
    let templateName: String
    
    public init(templateName: String) {
        self.templateName = templateName
    }
}
