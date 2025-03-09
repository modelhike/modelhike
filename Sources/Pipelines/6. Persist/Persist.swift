//
//  Persist.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
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
