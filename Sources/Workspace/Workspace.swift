//
// Workspace.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class Workspace {
    private var sandbox: Sandbox
    var model: AppModel
    
    private var modifiers: [Modifier] = []
    private var statements: [any FileTemplateStmtConfig] = []
    public internal(set) var config: PipelineConfig
    
    public private(set) var context: Context
    public internal(set) var isModelsLoaded = false
    public private(set) var isSymbolsLoaded = false

    //MARK: event handlers
    public var onLoadTemplate : LoadTemplateHandler {
        get { sandbox.onLoadTemplate }
        set { sandbox.onLoadTemplate = newValue }
    }
    
    //MARK: symbol loading
    public func loadSymbols(_ sym : Set<PreDefinedSymbols>? = nil) throws {
        if let sym = sym {
            if let _ = sym.firstIndex(of: .typescript) {
                self.add(modifiers: TypescriptLib.functions)
                
                if let _ = sym.firstIndex(of: .mongodb_typescript) {
                    self.add(modifiers: MongoDB_TypescriptLib.functions(sandbox: sandbox))
                }
            }
            
            if let _ = sym.firstIndex(of: .java) {
                self.add(modifiers: JavaLib.functions)
            }
            
            //add GraphQL related fns
            self.add(modifiers: GraphQLLib.functions)
            
            if sym.firstIndex(of: .noMocking) == nil {
                //"no mock" is not specified; so, load default mocking
                self.add(modifiers: MockDataLib.functions(sandbox: sandbox))
            }
            
        } else { //nothing provided; so, just load some common modifiers alsone
            
            self.add(modifiers: MockDataLib.functions(sandbox: sandbox))
        }
        
        context.symbols.template.add(stmts: self.statements)
        context.symbols.template.add(modifiers: self.modifiers)
        
        isSymbolsLoaded = true
    }
    
    @discardableResult
    public func generateCodebase(container: String, usingBlueprintsFrom blueprintLoader: BlueprintRepository) throws -> String? {
        if !isModelsLoaded {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidAppState("No models Loaded!!!", pInfo)
        }
        
        if !isSymbolsLoaded {
            try loadSymbols()
        }
        
        print("🛠️ Container used: \(container)")
        print("🛠️ Output folder: \(output.path.string)")

        try output.ensureExists()
        try output.clearFiles()
        
        let rendering = try sandbox.generateFilesFor(container: container, usingBlueprintsFrom: blueprintLoader)
        
        print("✅ Generated \(context.generatedFiles.count) files ...")
        return rendering
    }
    
    public func render(string input: String, data: [String : Any]) throws -> String? {
        if !isSymbolsLoaded {
            try loadSymbols()
        }

        let rendering = try sandbox.renderTemplate(string: input, data: data)
        return rendering?.trim()
    }
    
    fileprivate func setupDefaultSymbols() {
        context.symbols.template.add(stmts: StatementsLibrary.statements)
        context.symbols.template.add(modifiers: DefaultModifiersLibrary.modifiers)
        context.symbols.template.add(infixOperators : DefaultOperatorsLibrary.infixOperators)
        
        context.symbols.template.add(modifiers: ModelLib.functions(sandbox: sandbox))
        context.symbols.template.add(modifiers: GenerationLib.functions)
    }
    
    public func add(modifiers modifiersList: [Modifier]...) {
        let modifiers = modifiersList.flatMap( { $0 })
        self.modifiers.append(contentsOf: modifiers)
    }
    
    public func add(stmts stmtsList: [any FileTemplateStmtConfig]...) {
        let stmts = stmtsList.flatMap( { $0 })
        self.statements.append(contentsOf: stmts)
    }
    
    public var output : OutputFolder {
        get { self.context.paths.output }
        set {
            self.context.paths.output = newValue
        }
    }
    
    public var basePath : LocalPath {
        get { self.context.paths.basePath }
        set {
            self.context.paths = ContextPaths(basePath: newValue)
        }
    }
    
    public var debugLog : ContextDebugLog {
        get { self.context.debugLog }
        set { self.context.debugLog = newValue }
    }
        
    internal init() {
        self.config = PipelineConfig()

        let basePath = SystemFolder.documents.path / "codegen"
        let paths = ContextPaths(basePath: basePath)
        
        self.context = Context(paths: paths)

        self.sandbox = CodeGenerationSandbox(context: context)
        self.model = sandbox.model
        
        setupDefaultSymbols()
    }
}

public enum PreDefinedSymbols {
    case typescript, mongodb_typescript, java, noMocking
}
