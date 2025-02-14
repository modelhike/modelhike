//
// Workspace.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class Workspace {
    private var sandbox: Sandbox
    private var model: AppModel
    
    private var modifiers: [Modifier] = []
    private var statements: [any FileTemplateStmtConfig] = []
    public private(set) var context: Context
    public private(set) var isModelsLoaded = false
    public private(set) var isSymbolsLoaded = false

    //MARK: event handlers
    public var onLoadTemplate : LoadTemplateHandler {
        get { sandbox.onLoadTemplate }
        set { sandbox.onLoadTemplate = newValue }
    }
    
    //MARK: Model loading
    public func loadModels(from repo: ModelRepository) throws {
        do {
            try repo.loadModel(to: model)
            try repo.loadGenerationConfigIfAny()
            
            try repo.processAfterLoad(model: model, with: context)
            
            if model.types.items.count > 0 {
                isModelsLoaded = true
            }
        } catch let err {
            printError(err)
            print("❌❌ ERROR IN LOADING MODELS ❌❌")
        }
    }
    
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
    public func generateCodebase(container: String, usingBlueprintsFrom blueprintLoader: BlueprintRepository) -> String? {
        do {
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
            
        } catch let err {
            printError(err)
            print("❌❌❌ TERMINATED DUE TO ERROR ❌❌❌")
            return nil
        }
    }
    
    public func render(string input: String, data: [String : Any]) -> String? {
        do {
            if !isSymbolsLoaded {
                try loadSymbols()
            }

            let rendering = try sandbox.renderTemplate(string: input, data: data)
            return rendering?.trim()

        } catch let err {
            printError(err)
            print("❌❌❌ TERMINATED DUE TO ERROR ❌❌❌")
            return nil
        }
    }
    
    fileprivate func printError(_ err: Error) {
        let callStackInfo = StringTemplate {
            "[Call Stack]"
            
            for log in context.debugLog.stack {
                String.newLine
                log.callStackItem.renderForDisplay()
            }
        }
        
        let memoryVarsInfo = StringTemplate {
            "[Memory]"
            
            for va in context.variables {
                String.newLine
                let value = va.value
                
                if let arr = value as? [Any] {
                    "\(va.key) =" + .newLine
                    for item in arr {
                        "| \(item)"
                    }
                } else if let optionalValue = value as? Optional<Any> {  // Cast to Optional<Any>
                    if let unwrappedValue = optionalValue {
                        "\(va.key) = \(unwrappedValue)"
                    } else {
                        "\(va.key) = null"
                    }
                } else {
                    "\(va.key) = \(va.value)"
                }
            }
        }
        
        let extraInfo = StringTemplate {
            callStackInfo
            String.newLine
            String.newLine
            memoryVarsInfo
        }.toString()
        
        if let parseErr = err as? ParsingError {
            let pInfo = parseErr.pInfo
            let msg = """
                      🐞🐞 ERROR WHILE PARSING 🐞🐞
                       \(pInfo.identifier) [\(pInfo.lineNo)] \(parseErr.info)
                      
                      \(extraInfo)
                      
                      """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let parseErr = err as? Model_ParsingError {
            let pInfo = parseErr.pInfo
            let msg = """
                      🐞🐞 ERROR WHILE PARSING MODELS 🐞🐞
                       \(pInfo.identifier) [\(pInfo.lineNo)] \(parseErr.info)
                      
                      \(extraInfo)
                      
                      """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let evalErr = err as? EvaluationError {
            let pInfo = evalErr.pInfo

            var info = ""
            if case let .invalidAppState(string, _) = evalErr {
                info = string
            } else if case let .invalidInput(string, _) = evalErr {
                info = string
            } else {
                info = evalErr.info
            }
            let msg = """
                  🐞🐞 ERROR DURING EVAL 🐞🐞
                   \(pInfo.identifier) [\(pInfo.lineNo)] \(info)
                  
                  \(extraInfo)
                  
                  """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let err = err as? ErrorWithMessageAndParsedInfo {
            let msg = """
                  🐞🐞 UNKNOWN ERROR 🐞🐞
                   \(err.info)
                  
                  \(extraInfo)
                  
                  """
            print(msg)
            //print(Thread.callStackSymbols)
        } else {
            print("❌❌ UNKNOWN INTERNAL ERROR ❌❌")
        }
        
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
    
    public init() {
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
