//
//  FileGenerator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol FileGeneratorProtocol {
    var base_generation_dir: OutputFolder {get}
    mutating func setRelativePath(_ path: String) throws
    
    func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) throws -> TemplateRenderedFile?
    func generateFileWithData(_ filename: String, template: String, data: [String: Any], with pInfo: ParsedInfo) throws -> TemplateRenderedFile?
    func copyFile(_ filename: String, with pInfo: ParsedInfo) throws -> StaticFile
    func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> StaticFile
    
    func copyFolder(_ path: String, with pInfo: ParsedInfo) throws -> StaticFolder
    func copyFolder(_ path: String, to newPath: String, with pInfo: ParsedInfo) throws -> StaticFolder
    func renderFolder(_ path: String, to newPath: String, with pInfo: ParsedInfo) throws -> RenderedFolder

    func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile?
    func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile?
}

