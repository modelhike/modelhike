//
//  CodeGenerationSandbox.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class CodeGenerationSandbox : GenerationSandbox {
    public private(set) var templateSoup: TemplateSoup
    private var generation_dir: OutputFolder
    public private(set) var base_generation_dir: OutputFolder

    public var model: AppModel { context.model }
    public var config: OutputConfig { context.config }

    public private(set) var context: GenerationContext
    private var modifiers: [Modifier] = []
    private var statements: [any FileTemplateStmtConfig] = []
    
    var lineParser : LineParserDuringGeneration
    public private(set) var isSymbolsLoaded = false

    //MARK: event handlers
    public var onLoadTemplate : LoadTemplateHandler {
        get { templateSoup.onLoadTemplate }
        set { templateSoup.onLoadTemplate = newValue }
    }
    
    //MARK: Generation code
    public func generateFilesFor(container: String, usingBlueprintsFrom blueprintLoader: Blueprint) throws -> String? {
        
        if !isSymbolsLoaded {
            try loadSymbols()
        }
        
        if try !blueprintLoader.blueprintExists() {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.blueprintDoesNotExist(blueprintLoader.blueprintName, pInfo)
        }
        
        guard let container = model.container(named: container) else {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidInput("There is no container called \(container)", pInfo)
        }
                
        let variables : [String: Any] = [
            "@container" : C4Container_Wrap(container, model: model),
            "@mock" : Mocking_Wrap()
        ]
        
        self.context.append(variables: variables)

        self.templateSoup.repo = blueprintLoader
        
        context.setWorkingDirectory("/")
        try self.setRelativePath("")
        
        let pInfo = ParsedInfo.dummyForMainFile(with: context)
        
        //handle special folders
        if blueprintLoader.hasFolder(SpecialFolderNames.root) {
            let specialActivity = SpecialActivityCallStackItem(activityName: "Rendering Root Folder")
            context.pushCallStack(specialActivity)

            try renderSpecialFolder(SpecialFolderNames.root, to: "/", pInfo: pInfo)
            context.popCallStack()

        } else {
            print("⚠️ Didn't find 'Root' folder in Blueprint !!!")
        }
        
        return try templateSoup.startMainScript(with: pInfo)
    }
    
    
    @discardableResult
    private func renderSpecialFolder(_ fromFolder: String, to toFolder: String, msg: String = "", pInfo: ParsedInfo) throws -> RenderedFolder {
        if msg.isNotEmpty {
            print(msg)
        }
        
        context.debugLog.renderingFolder(fromFolder, to: toFolder)
        let folder = try context.fileGenerator.renderFolder(fromFolder, to: toFolder, with: pInfo)
        return folder
    }
    
    public func render(string templateString: String, data: [String : Any]) throws -> String? {
        if !isSymbolsLoaded {
            try loadSymbols()
        }

        let pInfo = ParsedInfo.dummyForMainFile(with: context)

        return try templateSoup.renderTemplate(string: templateString, data: data, with: pInfo)
    }
    
    public init(model: AppModel, config: OutputConfig) {
        self.context = GenerationContext(model: model, config: config)
        self.lineParser  = LineParserDuringGeneration(identifier: "-", isStatementsPrefixedWithKeyword: true, with: context)
        
        self.templateSoup  = TemplateSoup(context: context)

        self.base_generation_dir = OutputFolder(config.output)
        self.generation_dir = self.base_generation_dir
        
        context.fileGenerator = self

        setupDefaultSymbols()
    }
    
    //MARK: symbol loading
    public func loadSymbols(_ sym : Set<PreDefinedSymbols>? = nil) throws {
        if let sym = sym {
            if let _ = sym.firstIndex(of: .typescript) {
                self.add(modifiers: TypescriptLib.functions)
                
                if let _ = sym.firstIndex(of: .mongodb_typescript) {
                    self.add(modifiers: MongoDB_TypescriptLib.functions(sandbox: self))
                }
            }
            
            if let _ = sym.firstIndex(of: .java) {
                self.add(modifiers: JavaLib.functions)
            }
            
            //add GraphQL related fns
            self.add(modifiers: GraphQLLib.functions)
            
            if sym.firstIndex(of: .noMocking) == nil {
                //"no mock" is not specified; so, load default mocking
                self.add(modifiers: MockDataLib.functions(sandbox: self))
            }
            
        } else { //nothing provided; so, just load some common modifiers alsone
            
            self.add(modifiers: MockDataLib.functions(sandbox: self))
        }
        
        context.symbols.template.add(stmts: self.statements)
        context.symbols.template.add(modifiers: self.modifiers)
        
        isSymbolsLoaded = true
    }
    
    fileprivate func setupDefaultSymbols() {
        context.symbols.template.add(stmts: StatementsLibrary.statements)
        context.symbols.template.add(modifiers: DefaultModifiersLibrary.modifiers)
        context.symbols.template.add(infixOperators : DefaultOperatorsLibrary.infixOperators)
        
        context.symbols.template.add(modifiers: ModelLib.functions(sandbox: self))
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
    
    //MARK: File generation protocol
        
    public func setRelativePath(_ path: String) throws {
        generation_dir = self.base_generation_dir.subFolder(path)
        try generation_dir.ensureExists()
    }
    
    public func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) throws -> RenderedFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = RenderedFile(filename: filename, filePath: generation_dir.path, template: template, renderer: self.templateSoup, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }
    
    public func generateFileWithData(_ filename: String, template: String, data: [String: Any], with pInfo: ParsedInfo) throws -> RenderedFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = RenderedFile(filename: filename, filePath: generation_dir.path, template: template, data: data, renderer: self.templateSoup, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }
    
    public func copyFile(_ filename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir.path, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }
        
    public func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir.path, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }
    
    public func copyFolder(_ foldername: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: foldername, path: generation_dir.path, pInfo: pInfo)
        
        try folder.copyFiles()
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        return folder
    }
    
    public func copyFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: newPath, path: generation_dir.path, pInfo: pInfo)
        
        try folder.copyFiles()
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        return folder
    }
    
    public func renderFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> RenderedFolder {
        //While rendering folder, onBeforeRenderFile is handled within the folder-rendering function
        //This is possibleas onBeforeRenderFile is part of templateSoup
        let folder = RenderedFolder(foldername: foldername, templateSoup: templateSoup, to: newPath, path: generation_dir.path, pInfo: pInfo)
        
        try folder.renderFiles()
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        return folder
    }
    
    public func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir.path, renderer: self.templateSoup, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }

    public func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir.path, renderer: self.templateSoup, pInfo: pInfo)
        
        try file.render()
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        return file
    }
}
