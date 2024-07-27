//
// Sandbox.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Sandbox {
    var basePath: LocalPath { get }
    var outputPath: LocalPath {get}
    var model: AppModel {get}
    var context: Context {get}
    
    var onLoadTemplate : LoadTemplateHandler {get set}
    
    mutating func generateFilesFor(container: String, usingTemplatesFrom templateLoader: TemplateRepository) throws -> String?
    func renderTemplate(string templateString: String, data: [String: Any]) throws -> String?
}
 
