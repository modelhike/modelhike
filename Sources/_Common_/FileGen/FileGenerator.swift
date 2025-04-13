//
//  FileGenerator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol FileGeneratorProtocol: Actor {
    var base_generation_dir: OutputFolder {get}
    func setRelativePath(_ path: String) throws
    
    func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) async throws -> TemplateRenderedFile?
    func generateFileWithData(_ filename: String, template: String, data: [String: Sendable], with pInfo: ParsedInfo) async throws -> TemplateRenderedFile?
    func copyFile(_ filename: String, with pInfo: ParsedInfo) async throws -> StaticFile
    func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) async throws -> StaticFile
    
    func copyFolder(_ path: String, with pInfo: ParsedInfo) async throws -> StaticFolder
    func copyFolder(_ path: String, to newPath: String, with pInfo: ParsedInfo) async throws -> StaticFolder
    func renderFolder(_ path: String, to newPath: String, with pInfo: ParsedInfo) async throws -> RenderedFolder

    func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile?
    func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile?
}

