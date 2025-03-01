//
// PipelineConfig.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public struct PipelineConfig : OutputConfig {
    public var basePath: LocalPath = SystemFolder.desktop.path {
        didSet {
            self.output = LocalFolder(path: basePath / "output")
        }
    }
    
    public var output : LocalFolder = SystemFolder.documents / "diagsoup-output"

    public var flags = ContextDebugFlags()
    public var errorOutput = ErrorOutputOptions()
    
    
    public var localBlueprintsPath: LocalPath? {
        didSet {
            if let path = self.localBlueprintsPath {
                blueprints.add(LocalFileBlueprintFinder(path: path))
            }
        }
    }
    
    public var blueprints = BlueprintAggregator()
    public func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint {
        return try blueprints.blueprint(named: name, with: pInfo)
    }
    
    public init() {}
}

public struct ErrorOutputOptions {
    public var includeMemoryVariablesDump: Bool = false
}

public enum BluePrintType {
    case localFileSystem, resources
}

public enum ModelLoaderType {
    case localFileSystem, inMemory
}

public protocol OutputConfig {
    var basePath: LocalPath {get set}
    var output : LocalFolder {get set}

    var flags: ContextDebugFlags {get set}
    var errorOutput: ErrorOutputOptions {get set}
    
    var localBlueprintsPath: LocalPath? {get set}
    var blueprints: BlueprintAggregator {get set}
    func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint
}
