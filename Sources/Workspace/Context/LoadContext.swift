//
// LoadContext.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public class LoadContext : Context {
    public private(set) var model: AppModel
    public var debugLog = ContextDebugLog()
    public var events = CodeGenerationEvents()
    
    public internal(set) var symbols = ContextSymbols()
    public private(set) var objManager = ObjectAttributeManager()

    public var currentState = ContextState()
    public private(set) var config : PipelineConfig
    
    //Expression Evaluation
    public private(set) var evaluator = ExpressionEvaluator()

    /// Context can have different snapshots depending upon outer/inner scope they are used
    /// E.g For loop variable has a inner scope and will have a separate context
    /// If `pushSnapshot` is called, it saves a snapshot of the current context state to a stack
    /// When `popSnapshot` is called, it discards any  changes after the last snapshot, by restoring latst snapshot
    public var snapshotStack : [ContextState] = []
    
    public init(config: PipelineConfig) {
        self.config = config
        self.model = AppModel()
    }
    
    public init(model: AppModel, config: PipelineConfig) {
        self.config = config
        self.model = model
    }
    
    public convenience init(model: AppModel, config: PipelineConfig, data: StringDictionary) {
        self.init(model: model, config: config)
        self.replace(variables: data)
    }
}
