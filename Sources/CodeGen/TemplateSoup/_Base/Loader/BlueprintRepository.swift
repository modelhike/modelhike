//
// TemplateRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol BlueprintRepository : InputFileRepository {
    var blueprintName: String {get}
    func blueprintExists() throws -> Bool
    func loadTemplate(fileName: String, with pInfo: ParsedInfo) throws -> Template
}

public protocol InputFileRepository {
    func copyFiles(foldername: String, to folder: LocalFolder, with pInfo: ParsedInfo) throws
    func renderFiles(foldername: String, to folder: LocalFolder, using templateSoup: TemplateSoup, with pInfo: ParsedInfo) throws

    func readTextContents(filename: String, with pInfo: ParsedInfo) throws -> String
    func hasFolder(_ foldername: String) -> Bool
}
