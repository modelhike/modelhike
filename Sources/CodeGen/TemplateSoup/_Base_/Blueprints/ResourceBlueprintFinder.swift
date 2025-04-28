//
//  ResourceBlueprintFinder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ResourceBlueprintFinder {
    public private(set) var blueprintsRoot: String
    public private(set) var resourceRoot: String
    var bundle: Bundle
    
    public func blueprint(named name: String, with pInfo: ParsedInfo) async throws -> any Blueprint {
        if let ctx = pInfo.ctx as? GenerationContext {
            return ResourceBlueprintLoader(blueprint: name, blueprintsRoot: blueprintsRoot, resourceRoot: resourceRoot, bundle: bundle, with: ctx)
        } else {
            fatalError(#function + ": unknown context passed")
        }
    }
    
    public init(bundle: Bundle) {
        self.bundle = bundle
        self.blueprintsRoot = "/Resources/blueprints/"
        self.resourceRoot = "/Resources/"
    }
}

