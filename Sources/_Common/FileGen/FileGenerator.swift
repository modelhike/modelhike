//
// FileGenerator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol FileGeneratorProtocol {
    var generation_dir: LocalPath {get}
    mutating func setRelativePath(_ path: String) throws
    
    func generateFile(_ filename: String, template: String) throws -> RenderedFile
    func generateFileWithData(_ filename: String, template: String, data: [String: Any]) throws -> RenderedFile
    func copyFile(_ filename: String) throws -> StaticFile
    func copyFile(_ filename: String, to newFilename: String) throws -> StaticFile
    func copyFolder(_ path: String) throws -> StaticFolder
    func copyFolder(_ path: String, to newPath: String) throws -> StaticFolder
    
    func fillPlaceholdersAndCopyFile(_ filename: String) throws -> PlaceHolderFile
    func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String) throws -> PlaceHolderFile
}

