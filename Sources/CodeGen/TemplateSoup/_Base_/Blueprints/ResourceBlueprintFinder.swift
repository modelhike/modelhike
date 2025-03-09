//
//  ResourceBlueprintFinder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class ResourceBlueprintFinder: BlueprintFinder {
    public private(set) var blueprintsRoot: String
    public private(set) var resourceRoot: String
    var bundle: Bundle
    
    public lazy var blueprintsAvailable: [String] = getListOfblueprintsAvailable()
    
    open func getListOfblueprintsAvailable() -> [String] {
        fatalError("This method must be overridden")
    }
    
    public func hasBlueprint(named name: String) -> Bool {
        blueprintsAvailable.contains(name)
    }
    
    public func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint {
        if let ctx = pInfo.ctx as? GenerationContext {
            return ResourceBlueprintLoader(blueprint: name, blueprintsRoot: blueprintsRoot, resourceRoot: resourceRoot, bundle: bundle, with: ctx)
        } else {
            fatalError("unknown context passed")
        }
    }
    
    public init(bundle: Bundle) {
        self.bundle = bundle
        self.blueprintsRoot = "/Resources/blueprints/"
        self.resourceRoot = "/Resources/"
    }
}

