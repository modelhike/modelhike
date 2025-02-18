//
// Pipelines.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Pipelines {
    
    public static let codegen = Pipeline {
        Load.models()
        Render.code()
    }
    
    public static let content = Pipeline {
        Load.contentsFrom(folder: "contents")
        LoadPagesPass(folderName: "localFolder")
        LoadTemplatesPass(folderName: "localFolder")
    }
    
    public static let empty = Pipeline {
    }
}
