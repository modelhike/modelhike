//
// PipelineConfig.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public struct PipelineConfig {
    public var basePath: LocalPath = SystemFolder.desktop.path
    public var localBlueprintsPath: LocalPath? {
        didSet {
            if let path = self.localBlueprintsPath {
                blueprints.add(LocalFileBlueprintFinder(path: path))
            }
        }
    }

    public var modelLoaderType: ModelLoaderType = .localFileSystem

    public var errorOutput = ErrorOutputOptions()
    
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
