//
//  CodeGenerationSandbox.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor CodeGenerationSandbox : GenerationSandbox {
    public private(set) var templateSoup: TemplateSoup
    private var generation_dir: OutputFolder
    public private(set) var base_generation_dir: OutputFolder

    public var model: AppModel { context.model }
    public var config: OutputConfig { get async { await context.config }}

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
    public func generateFilesFor(container: String, usingBlueprintsFrom blueprintLoader: Blueprint) async throws -> String? {
        
        if !isSymbolsLoaded {
            try await loadSymbols()
        }
        
        if try !blueprintLoader.blueprintExists() {
            let pInfo = await ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.blueprintDoesNotExist(blueprintLoader.blueprintName, pInfo)
        }
        
        guard let container = await model.container(named: container) else {
            let pInfo = await ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidInput("There is no container called \(container)", pInfo)
        }
                
        let variables : [String: Sendable] = [
            "@container" : C4Container_Wrap(container, model: model),
            "@mock" : Mocking_Wrap()
        ]
        
        await self.context.append(variables: variables)

        self.templateSoup.repo = blueprintLoader
        
        await context.setWorkingDirectory("/")
        try self.setRelativePath("")
        
        let pInfo = await ParsedInfo.dummyForMainFile(with: context)
        
        //handle special folders
        if blueprintLoader.hasFolder(SpecialFolderNames.root) {
            let specialActivity = SpecialActivityCallStackItem(activityName: "Rendering Root Folder")
            await context.pushCallStack(specialActivity)

            try renderSpecialFolder(SpecialFolderNames.root, to: "/", pInfo: pInfo)
            await context.popCallStack()

        } else {
            print("⚠️ Didn't find 'Root' folder in Blueprint !!!")
        }
        
        return try templateSoup.startMainScript(with: pInfo)
    }
    
    
    @discardableResult
    private func renderSpecialFolder(_ fromFolder: String, to toFolder: String, msg: String = "", pInfo: ParsedInfo) async throws -> RenderedFolder {
        if msg.isNotEmpty {
            print(msg)
        }
        
        await context.debugLog.renderingFolder(fromFolder, to: toFolder)
        let folder = try await context.fileGenerator.renderFolder(fromFolder, to: toFolder, with: pInfo)
        return folder
    }
    
    public func render(string templateString: String, data: [String : Sendable]) async throws -> String? {
        if !isSymbolsLoaded {
            try await loadSymbols()
        }

        let pInfo = await ParsedInfo.dummyForMainFile(with: context)

        return try templateSoup.renderTemplate(string: templateString, data: data, with: pInfo)
    }
    
    public init(model: AppModel, config: OutputConfig) async {
        self.context = GenerationContext(model: model, config: config)
        self.lineParser  = LineParserDuringGeneration(identifier: "-", isStatementsPrefixedWithKeyword: true, with: context)
        
        self.templateSoup  = TemplateSoup(context: context)

        self.base_generation_dir = OutputFolder(config.output)
        self.generation_dir = self.base_generation_dir
        
        context.fileGenerator = self

        await setupDefaultSymbols()
    }
    
    //MARK: symbol loading
    public func loadSymbols(_ sym : Set<PreDefinedSymbols>? = nil) async throws {
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
                await self.add(modifiers: MockDataLib.functions(sandbox: self))
            }
            
        } else { //nothing provided; so, just load some common modifiers alsone
            
            await self.add(modifiers: MockDataLib.functions(sandbox: self))
        }
        
        await context.symbols.addTemplate(stmts: self.statements)
        await context.symbols.addTemplate(modifiers: self.modifiers)
        
        isSymbolsLoaded = true
    }
    
    fileprivate func setupDefaultSymbols() async {
        await context.symbols.addTemplate(stmts: StatementsLibrary.statements)
        await context.symbols.addTemplate(modifiers: DefaultModifiersLibrary.modifiers())
        await context.symbols.addTemplate(infixOperators : DefaultOperatorsLibrary.infixOperators)
        
        await context.symbols.addTemplate(modifiers: ModelLib.functions(sandbox: self))
        await context.symbols.addTemplate(modifiers: GenerationLib.functions())
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
        if path.isNotEmpty && path != "/" {
            generation_dir = self.base_generation_dir.relativeFolder(path)
            try generation_dir.ensureExists()
        } else {
            generation_dir = self.base_generation_dir
            try generation_dir.ensureExists()
        }
    }
    
    public func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) async throws -> TemplateRenderedFile? {
        if try await !context.events.canRender(filename: filename, templatename: template, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = TemplateRenderedFile(filename: filename, template: template, renderer: self.templateSoup, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }
    
    public func generateFileWithData(_ filename: String, template: String, data: [String: Sendable], with pInfo: ParsedInfo) async throws -> TemplateRenderedFile? {
        if try await !context.events.canRender(filename: filename, templatename: template, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = TemplateRenderedFile(filename: filename, template: template, data: data, renderer: self.templateSoup, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }
    
    public func copyFile(_ filename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: filename, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }
        
    public func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: newFilename, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }
    
    public func copyFolder(_ foldername: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: foldername,  pInfo: pInfo)
        
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try folder.copyFiles()
        return folder
    }
    
    public func copyFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: newPath, pInfo: pInfo)
        
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try folder.copyFiles()
        return folder
    }
    
    public func renderFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> RenderedFolder {
        //While rendering folder, onBeforeRenderFile is handled within the folder-rendering function
        //This is possibleas onBeforeRenderFile is part of templateSoup
        let folder = RenderedFolder(foldername: foldername, templateSoup: templateSoup, to: newPath,  pInfo: pInfo)
        
        generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try folder.renderFiles()
        return folder
    }
    
    public func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile? {
        if try await !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: filename, renderer: self.templateSoup, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }

    public func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile? {
        if try await !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: newFilename, renderer: self.templateSoup, pInfo: pInfo)
        
        generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try file.render()
        return file
    }
}
