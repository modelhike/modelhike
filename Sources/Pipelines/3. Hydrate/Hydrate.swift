//
// Render.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Hydrate {
    
}

public extension Hydrate {
    static func models() -> LoadingPass  {
        HydrateModelsPass()
    }
    
    static func annotations() -> LoadingPass  {
        PassDownAnnotationsPass()
    }
}
