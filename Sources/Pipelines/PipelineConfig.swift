//
// PipelineConfig.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public struct PipelineConfig {
    public var basePath: LocalPath = SystemFolder.desktop.path

    public var blueprintType: BluePrintType = .localFileSystem
    public var modelLoaderType: ModelLoaderType = .localFileSystem

    public var errorOutput = ErrorOutputOptions()
    
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
