//
//  LocalFileBlueprintFinder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public class LocalFileBlueprintFinder: BlueprintFinder {
    public var paths: [LocalPath]
    public let rootPath: LocalPath
    
    public func hasBlueprint(named name: String) -> Bool {
        blueprintsAvailable.contains(name)
    }
    
    public func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint {
        if let ctx = pInfo.ctx as? GenerationContext {
            return LocalFileBlueprintLoader(blueprint: name, path: rootPath, with: ctx)
        } else {
            fatalError("unknown context passed")
        }
    }
    
    public lazy var blueprintsAvailable: [String] = {
        var names: [String] = []
        var folder = LocalFolder(path: rootPath)
        
        for subFolder in folder.subFolders {
            names.append(subFolder.name)
        }
        
        return names
    }()

    internal init(path: LocalPath) {
        self.paths = [path]
        self.rootPath = path
    }
}

public protocol BlueprintFinder {
    var blueprintsAvailable : [String] {get}
    func hasBlueprint(named name: String) -> Bool
    func blueprint(named name: String, with pInfo: ParsedInfo) throws -> Blueprint
}
