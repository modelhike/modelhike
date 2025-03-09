//
//  Context.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public typealias StringDictionary = [String: Any]

public class GenerationContext: Context {
    public var events = CodeGenerationEvents()
    public var debugLog = ContextDebugLog()

    public private(set) var evaluator = ExpressionEvaluator()

    public private(set) var objManager = ObjectAttributeManager()
    public internal(set) var symbols = ContextSymbols()
    public private(set) var config: OutputConfig

    public var currentState = ContextState()

    /// Context can have different snapshots depending upon outer/inner scope they are used
    /// E.g For loop variable has a inner scope and will have a separate context
    /// If `pushSnapshot` is called, it saves a snapshot of the current context state to a stack
    /// When `popSnapshot` is called, it discards any  changes after the last snapshot, by restoring latst snapshot
    public private(set) var snapshotStack = SnapshotStack()

    // File Generation
    public var fileGenerator: FileGeneratorProtocol!
    var generatedFiles: [String] = []
    var generatedFolders: [String] = []

    public func addGenerated(filePath: String) {
        self.generatedFiles.append(filePath)
    }

    public func addGenerated(folderPath: LocalPath) {
        return addGenerated(folderPath: LocalFolder(path: folderPath))
    }
    
    public func addGenerated(folderPath: LocalFolder) {
        self.generatedFolders.append(folderPath.pathString)
        
        let files = folderPath.files

        for file in files {
            self.generatedFiles.append(file.pathString)
        }

        //add files in subfolder also
        for folder in folderPath.subFolders {
            self.generatedFolders.append(folder.pathString)

            let files = folder.files

            for file in files {
                self.generatedFiles.append(file.pathString)
            }
        }
    }

    //parsed model
    public let model: AppModel

    public init(model: AppModel, config: OutputConfig) {
        self.config = config
        self.events = config.events
        self.debugLog.flags = config.flags
        self.model = model
    }

    public convenience init(model: AppModel, config: OutputConfig, data: StringDictionary) {
        self.init(model: model, config: config)
        self.replace(variables: data)
    }
}
