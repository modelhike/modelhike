//
//  LoadModelsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct LoadModelsPass: LoadingPass {

    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        var repo: ModelRepository

        do {
            //TODO: Also update in Discover phase
            //        if config.modelLoaderType == .localFileSystem {
            repo = await LocalFileModelLoader(path: ws.config.basePath, with: ws.context)
            //let modelRepo = inlineModel(ws)

            try await repo.loadModel(to: ws.model)
            try await repo.loadGenerationConfigIfAny()

            if await ws.model.types.items.count > 0 {
                await ws.isModelsLoaded(true)

                let domainTypesCount = await ws.model.containers.types.count
                let commonTypesCount = await ws.model.commonModel.types.count
                print(
                    "💡 Loaded domain types: \(domainTypesCount), common types: \(commonTypesCount)")

                return true

            } else {
                await ws.isModelsLoaded(false)
                print("❌❌ No Model Found!!!")
                return false
            }
        } catch let err {
            await printError(err, workspace: ws)
            print("❌❌ ERROR IN LOADING MODELS ❌❌")
            return false
        }
    }

    fileprivate func printError(_ err: Error, workspace: Workspace) async {
        let printer = PipelineErrorPrinter()
        await printer.printError(err, workspace: workspace)
    }

    public init() {
    }
}
