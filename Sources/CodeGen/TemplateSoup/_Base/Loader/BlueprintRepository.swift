//
// TemplateRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol BlueprintRepository : InputFileRepository {
    var blueprintName: String {get}
    func blueprintExists() -> Bool
    func loadTemplate(fileName: String, pInfo: ParsedInfo) throws -> Template
}

public protocol InputFileRepository {
    func copyFiles(foldername: String, to folder: LocalFolder, pInfo: ParsedInfo) throws
    func renderFiles(foldername: String, to folder: LocalFolder, using templateSoup: TemplateSoup, pInfo: ParsedInfo) throws

    func readTextContents(filename: String, pInfo: ParsedInfo) throws -> String
    func hasFolder(_ foldername: String) -> Bool
}
