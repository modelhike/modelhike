//
//  PipelineConfig.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public struct PipelineConfig : OutputConfig {
    public var basePath: LocalPath = SystemFolder.desktop.path {
        didSet {
            self.output = LocalFolder(path: basePath / "output")
        }
    }
    
    public var outputItemType : OutputArtifactType = .container
    public var containersToOutput: [String] = []
    public var containerGroupsToOutput: [String] = []
    public var systemViewsToOutput: [String] = []

    public var output : LocalFolder = SystemFolder.documents / "diagsoup-output"

    public var modelLoaderType : ModelLoaderType = .localFileSystem
    
    public var events = CodeGenerationEvents()
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
    
    public init() {}
}

public enum BluePrintType {
    case localFileSystem, resources
}

public enum ModelLoaderType {
    case localFileSystem, inMemory
}

public enum OutputArtifactType {
    case container, containerGroup, systemView
}

public protocol OutputConfig {
    var basePath: LocalPath {get set}
    
    var outputItemType : OutputArtifactType {get set}
    var containersToOutput: [String] {get set}
    var containerGroupsToOutput: [String] {get set}
    var systemViewsToOutput: [String] {get set}
    
    var output : LocalFolder {get set}

    var modelLoaderType : ModelLoaderType {get set}
    
    var events : CodeGenerationEvents {get set}
    var flags: ContextDebugFlags {get set}
    var errorOutput: ErrorOutputOptions {get set}
    
    var localBlueprintsPath: LocalPath? {get set}
    var blueprints: BlueprintAggregator {get set}
    func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint
}
