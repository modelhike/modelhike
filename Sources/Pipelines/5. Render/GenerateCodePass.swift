//
// GenerateCodePass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateCodePass : RenderingPass {

    public func runIn(_ ws: Workspace, phase: RenderPhase) async throws -> Bool {
        var templatesRepo: BlueprintRepository
        
        
        let templatesPath = LocalPath(relativePath: "../Hub/CodeCave/DiagSoup/diagsoup-blueprints/Sources/Resources/blueprints", basePath: SystemFolder.documents.path)
        
        let blueprint = "api-nestjs-monorepo"
        //let blueprint = "api-springboot-monorepo"

        if blueprint == "api-nestjs-monorepo" {
            try ws.loadSymbols([.typescript, .mongodb_typescript])
        } else if blueprint == "api-springboot-monorepo" {
            try ws.loadSymbols([.java])
        }
        
//        if config.blueprintType == .resources {
//
//        } else {
        templatesRepo = LocalFileBlueprintLoader(blueprint: blueprint, path: templatesPath, with: ws.context)
//        }
        
        try ws.generateCodebase(container: "APIs", usingBlueprintsFrom: templatesRepo)

        return true
    }
    
    fileprivate func printError(_ err: Error, workspace: Workspace) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: workspace)
    }
    
    public init() {
    }
}
