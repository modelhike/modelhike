//
// TemplateRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol TemplateRepository : InputFileRepository {
    func loadTemplate(fileName: String) throws -> TemplateSoupTemplate
}

public protocol InputFileRepository {
    func copyFiles(foldername: String, to folder: LocalFolder) throws
    func readTextContents(filename: String) throws -> String
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
