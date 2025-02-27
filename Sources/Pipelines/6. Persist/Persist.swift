//
// Persist.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Persist {
    
}

public extension Persist {
    static func toOutput() -> PipelinePass {
        GenerateOutputFoldersPass()
    }
    
//    static func to(folder localFolder: String) -> PipelinePass {
//
//    }
//    
//    static func to(awsS3 s3: String) -> PipelinePass {
//        
//    }
}
