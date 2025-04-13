//
//  Sandbox.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol GenerationSandbox : Sandbox, FileGeneratorProtocol {
    func generateFilesFor(container: String, usingBlueprintsFrom templateLoader: Blueprint) async throws -> String?
}

public protocol Sandbox: Actor {
    var model: AppModel {get}
    var context: GenerationContext {get}
    var config: OutputConfig {get async}
    
    var onLoadTemplate : LoadTemplateHandler {get set}
    func loadSymbols(_ sym : Set<PreDefinedSymbols>?) async throws
    
    func render(string templateString: String, data: [String: Sendable]) async throws -> String?
}
 
