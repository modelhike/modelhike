//
// GenerateFoldersPass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateOutputFoldersPass : PersistancePass {
    public func runIn(phase: PersistPhase, pipeline: Pipeline) async throws -> Bool {
        
        var totalFilesGenerated: Int = 0
        try pipeline.config.output.deleteAllFilesAndFolders()
        
        for sandbox in pipeline.generationSandboxes {
            let output = sandbox.base_generation_dir
            
            try output.persist(with: sandbox.context)
            
            totalFilesGenerated += sandbox.context.generatedFiles.count
        }
        
        print("✅ Generated \(totalFilesGenerated) files ...")
        return true
    }
}
