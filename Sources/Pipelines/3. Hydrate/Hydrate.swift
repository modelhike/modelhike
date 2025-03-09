//
//  Hydrate.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum Hydrate {

}

extension Hydrate {
    public static func models() -> LoadingPass {
        HydrateModelsPass()
    }

    public static func annotations() -> LoadingPass {
        PassDownAnnotationsPass()
    }
}
