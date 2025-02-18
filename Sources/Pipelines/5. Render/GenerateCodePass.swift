//
// GenerateCodePass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateCodePass : RenderingPass {

    public func runIn(_ sandbox: Sandbox, phase: RenderPhase) async throws -> Bool {
        
        var templatesRepo: Blueprint
        
        let blueprint = "api-nestjs-monorepo"
        //let blueprint = "api-springboot-monorepo"

        if blueprint == "api-nestjs-monorepo" {
            try sandbox.loadSymbols([.typescript, .mongodb_typescript])
        } else if blueprint == "api-springboot-monorepo" {
            try sandbox.loadSymbols([.java])
        }
        
        let pInfo = ParsedInfo.dummyForAppState(with: sandbox.context)
        templatesRepo = try sandbox.config.blueprint(named: blueprint, with: pInfo)
        
        try generateCodebase(container: "APIs", usingBlueprintsFrom: templatesRepo, sandbox: sandbox)

        return true
    }
    
    @discardableResult
    public func generateCodebase(container: String, usingBlueprintsFrom blueprintLoader: Blueprint, sandbox: Sandbox) throws -> String? {
        var mutableSandbox = sandbox
        
//        if !isModelsLoaded {
//            let pInfo = ParsedInfo.dummyForAppState(with: sandbox.context)
//            throw EvaluationError.invalidAppState("No models Loaded!!!", pInfo)
//        }
        
        let output = sandbox.config.output
        
        print("🛠️ Container used: \(container)")
        print("🛠️ Output folder: \(output.path.string)")

        try output.ensureExists()
        try output.clearFiles()
        
        let rendering = try mutableSandbox.generateFilesFor(container: container, usingBlueprintsFrom: blueprintLoader)
        
        print("✅ Generated \(mutableSandbox.context.generatedFiles.count) files ...")
        return rendering
    }
    fileprivate func printError(_ err: Error, workspace: Workspace) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: workspace)
    }
    
    public init() {
    }
}
