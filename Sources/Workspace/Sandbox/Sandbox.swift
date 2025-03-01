//
// Sandbox.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol GenerationSandbox : Sandbox, FileGeneratorProtocol {
    mutating func generateFilesFor(container: String, usingBlueprintsFrom templateLoader: Blueprint) throws -> String?
}

public protocol Sandbox {
    var model: AppModel {get}
    var context: GenerationContext {get}
    var config: OutputConfig {get}
    
    var onLoadTemplate : LoadTemplateHandler {get set}
    func loadSymbols(_ sym : Set<PreDefinedSymbols>?) throws
    
    func render(string templateString: String, data: [String: Any]) throws -> String?
}
 
