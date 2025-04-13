//
//  LoadContext.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor LoadContext : Context {
    public let model: AppModel
    public var debugLog = ContextDebugLog()
    public var events = CodeGenerationEvents()
    
    public internal(set) var symbols = ContextSymbols()
    public private(set) var objManager = ObjectAttributeManager()

    public var currentState = ContextState()
    public let config : OutputConfig
    
    //Expression Evaluation
    public private(set) var evaluator = ExpressionEvaluator()

    /// Context can have different snapshots depending upon outer/inner scope they are used
    /// E.g For loop variable has a inner scope and will have a separate context
    /// If `pushSnapshot` is called, it saves a snapshot of the current context state to a stack
    /// When `popSnapshot` is called, it discards any  changes after the last snapshot, by restoring latst snapshot
    public private(set) var snapshotStack = SnapshotStack()
    
    public init(config: OutputConfig) {
        self.config = config
        self.debugLog.flags = config.flags
        self.model = AppModel()
    }
    
    public init(model: AppModel, config: OutputConfig) {
        self.config = config
        self.debugLog.flags = config.flags
        self.model = model
    }
    
    public init(model: AppModel, config: OutputConfig, data: StringDictionary) async {
        self.init(model: model, config: config)
        await self.currentState.variables.replace(variables: variables)
    }
}
