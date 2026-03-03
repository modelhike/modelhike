//
//  Blueprint.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Blueprint : InputFileRepository {
    var blueprintName: String {get}
    func blueprintExists() async throws -> Bool
    func loadTemplate(fileName: String, with pInfo: ParsedInfo) async throws -> Template
    func loadScriptFile(fileName: String, with pInfo: ParsedInfo) async throws -> Script
}

public protocol InputFileRepository: Actor {
    func copyFiles(foldername: String, to folder: OutputFolder, with pInfo: ParsedInfo) async throws
    func renderFiles(foldername: String, to folder: OutputFolder, using templateSoup: TemplateSoup, with pInfo: ParsedInfo) async throws

    func readTextContents(filename: String, with pInfo: ParsedInfo) async throws -> String
    func hasFolder(_ foldername: String) async -> Bool

    /// Returns the filenames (including extension) of all files directly inside `foldername`.
    /// Implementations that do not support filesystem enumeration (e.g. resource-bundle loaders)
    /// return an empty array via the default below.
    func listFiles(inFolder foldername: String) async -> [String]
}

public typealias RenderClosure = (@Sendable (String, ParsedInfo) async throws -> Void)
