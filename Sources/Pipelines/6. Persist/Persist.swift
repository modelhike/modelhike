//
// Persist.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Persist {
    
}

public extension Persist {
    static func to(folder localFolder: String) -> PipelinePass {
        LoadContentFromFolder(folderName: localFolder)
    }
    
    static func to(awsS3 s3: String) -> PipelinePass {
        LoadContentFromFolder(folderName: s3)
    }
}
