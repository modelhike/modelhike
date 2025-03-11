//
//  GenerateFoldersPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct GenerateOutputFoldersPass : PersistancePass {
    public func runIn(phase: PersistPhase, pipeline: Pipeline) async throws -> Bool {
        
        try pipeline.config.output.deleteAllFilesAndFolders()

        var totalFilesGenerated: Int = 0
        var totalFoldersGenerated: Int = 0
        
        for sandbox in pipeline.generationSandboxes {
            let output = sandbox.base_generation_dir
            
            try output.persist(with: sandbox.context)
            
            totalFilesGenerated += sandbox.context.generatedFiles.count
            totalFoldersGenerated += sandbox.context.generatedFolders.count
       }
        
        print("✅ Generated \(totalFilesGenerated) files, \(totalFoldersGenerated) folders ...")
        return true
    }
}
