//
//  Pipelines.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum Pipelines: Sendable {
    
    public static let codegen = Pipeline {
            Discover.models()
            Load.models()
            Hydrate.models()
            Hydrate.annotations()
            Render.code()
            Persist.toOutputFolder()
        }
    
    public static let content = Pipeline {
            Load.contentsFrom(folder: "contents")
            LoadPagesPass(folderName: "localFolder")
            LoadTemplatesPass(folderName: "localFolder")
        }
    
    public static let empty =  Pipeline {
        
    }
}
