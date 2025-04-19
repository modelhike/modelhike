//
//  PipelineConfig.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public struct PipelineConfig : OutputConfig {
    public var basePath: LocalPath = SystemFolder.documents.path {
        didSet {
            self.output = LocalFolder(path: basePath / "modelhike-output")
        }
    }
    
    public var output : LocalFolder = SystemFolder.documents / "modelhike-output"
    public var outputItemType : OutputArtifactType = .container
    
    public var containersToOutput: [String] = []
    public var containerGroupsToOutput: [String] = []
    public var systemViewsToOutput: [String] = []

    public var modelLoaderType : ModelLoaderType = .localFileSystem
    
    public var events = CodeGenerationEvents()
    public var flags = ContextDebugFlags()
    public var errorOutput = ErrorOutputOptions()
    
    public var localBlueprintsPath: LocalPath?
    
    public init() {}
}

public struct ErrorOutputOptions : Sendable{
    public var includeMemoryVariablesDump: Bool = false
    
    public init() {}
}

public enum BluePrintType {
    case localFileSystem, resources
}

public enum ModelLoaderType : Sendable{
    case localFileSystem, inMemory
}

public enum OutputArtifactType : Sendable{
    case container, containerGroup, systemView
}

public protocol OutputConfig: Sendable {
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
}
