//
// Context.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias StringDictionary = [String: Any]

public class GenerationContext: Context {
    public var events = CodeGenerationEvents()
    public var debugLog = ContextDebugLog()

    public private(set) var evaluator = ExpressionEvaluator()

    public private(set) var objManager = ObjectAttributeManager()
    public internal(set) var symbols = ContextSymbols()
    public private(set) var config: PipelineConfig

    public var currentState = ContextState()

    /// Context can have different snapshots depending upon outer/inner scope they are used
    /// E.g For loop variable has a inner scope and will have a separate context
    /// If `pushSnapshot` is called, it saves a snapshot of the current context state to a stack
    /// When `popSnapshot` is called, it discards any  changes after the last snapshot, by restoring latst snapshot
    public var snapshotStack: [ContextState] = []

    public func replace(variables: StringDictionary) {
        self.currentState.variables = variables
    }

    public func append(variables: StringDictionary) {
        variables.forEach {
            self.variables[$0.key] = $0.value
        }
    }

    // File Generation
    public var fileGenerator: FileGeneratorProtocol!
    var generatedFiles: [String] = []

    public func addGenerated(filePath: String) {
        self.generatedFiles.append(filePath)
    }

    public func addGenerated(folderPath: LocalFolder) throws {
        let files = folderPath.files

        for file in files {
            self.generatedFiles.append(file.pathString)
        }

        //add files in subfolder also
        for folder in folderPath.subFolders {
            let files = folder.files

            for file in files {
                self.generatedFiles.append(file.pathString)
            }
        }
    }

    //parsed model
    public let model: AppModel

    public init(model: AppModel, config: PipelineConfig) {
        self.config = config
        self.model = model
    }

    public convenience init(model: AppModel, config: PipelineConfig, data: StringDictionary) {
        self.init(model: model, config: config)
        self.replace(variables: data)
    }
}
