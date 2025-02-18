//
// GenerateCodePass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateCodePass : RenderingPass {

    public func runIn(_ ws: Workspace, phase: RenderPhase) async throws -> Bool {
        var templatesRepo: Blueprint
        
        let blueprint = "api-nestjs-monorepo"
        //let blueprint = "api-springboot-monorepo"

        if blueprint == "api-nestjs-monorepo" {
            try ws.loadSymbols([.typescript, .mongodb_typescript])
        } else if blueprint == "api-springboot-monorepo" {
            try ws.loadSymbols([.java])
        }
        
        let pInfo = ParsedInfo.dummyForAppState(with: ws.context)
        templatesRepo = try ws.config.blueprint(named: blueprint, with: pInfo)
        
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
