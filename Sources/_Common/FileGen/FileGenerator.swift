//
// FileGenerator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol FileGeneratorProtocol {
    var generation_dir: LocalPath {get}
    mutating func setRelativePath(_ path: String) throws
    
    func generateFile(_ filename: String, template: String, pInfo: ParsedInfo) throws -> RenderedFile?
    func generateFileWithData(_ filename: String, template: String, data: [String: Any], pInfo: ParsedInfo) throws -> RenderedFile?
    func copyFile(_ filename: String, pInfo: ParsedInfo) throws -> StaticFile
    func copyFile(_ filename: String, to newFilename: String, pInfo: ParsedInfo) throws -> StaticFile
    func copyFolder(_ path: String, pInfo: ParsedInfo) throws -> StaticFolder
    func copyFolder(_ path: String, to newPath: String, pInfo: ParsedInfo) throws -> StaticFolder
    func renderFolder(_ path: String, to newPath: String, pInfo: ParsedInfo) throws -> RenderedFolder

    func fillPlaceholdersAndCopyFile(_ filename: String, pInfo: ParsedInfo) throws -> PlaceHolderFile?
    func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, pInfo: ParsedInfo) throws -> PlaceHolderFile?
}

