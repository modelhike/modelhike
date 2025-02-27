//
// Sandbox.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol GenerationSandbox : Sandbox, FileGeneratorProtocol {
    
}

public protocol Sandbox {
    var model: AppModel {get}
    var context: GenerationContext {get}
    var config: PipelineConfig {get}
    
    var onLoadTemplate : LoadTemplateHandler {get set}
    func loadSymbols(_ sym : Set<PreDefinedSymbols>?) throws
    
    mutating func generateFilesFor(container: String, usingBlueprintsFrom templateLoader: Blueprint) throws -> String?
    func render(string templateString: String, data: [String: Any]) throws -> String?
}
 
