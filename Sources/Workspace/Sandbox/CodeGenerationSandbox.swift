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
    public var onLoadTemplate : LoadTemplateHandler { get async { await templateSoup.onLoadTemplate }}

    public func onLoadTemplate(_ newValue: @escaping LoadTemplateHandler) async {
        await templateSoup.onLoadTemplate( newValue )
    }
    
    //MARK: Generation code
    public func generateFilesFor(container: String, usingBlueprintsFrom blueprintLoader: Blueprint) async throws -> String? {
        
        if !isSymbolsLoaded {
            try await loadSymbols()
        }
        
        if try await !blueprintLoader.blueprintExists() {
            let pInfo = await ParsedInfo.dummyForAppState(with: context)
            throw await EvaluationError.blueprintDoesNotExist(blueprintLoader.blueprintName, pInfo)
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

        await self.templateSoup.blueprint( blueprintLoader )
        
        await context.setWorkingDirectory("/")
        try await self.setRelativePath("")
        
        let pInfo = await ParsedInfo.dummyForMainFile(with: context)
        
        //handle special folders
        if await blueprintLoader.hasFolder(SpecialFolderNames.root) {
            let specialActivity = SpecialActivityCallStackItem(activityName: "Rendering Root Folder")
            await context.pushCallStack(specialActivity)

            try await renderSpecialFolder(SpecialFolderNames.root, to: "/", pInfo: pInfo)
            await context.popCallStack()

        } else {
            print("⚠️ Didn't find 'Root' folder in Blueprint !!!")
        }
        
        return try await templateSoup.startMainScript(with: pInfo)
    }
    
    
    @discardableResult
    private func renderSpecialFolder(_ fromFolder: String, to toFolder: String, msg: String = "", pInfo: ParsedInfo) async throws -> RenderedFolder {
        if msg.isNotEmpty {
            print(msg)
        }
        
        context.debugLog.renderingFolder(fromFolder, to: toFolder)
        let folder = try await context.fileGenerator.renderFolder(fromFolder, to: toFolder, with: pInfo)
        return folder
    }
    
    public func render(string templateString: String, data: [String : Sendable]) async throws -> String? {
        if !isSymbolsLoaded {
            try await loadSymbols()
        }

        let pInfo = await ParsedInfo.dummyForMainFile(with: context)

        return try await templateSoup.renderTemplate(string: templateString, data: data, with: pInfo)
    }
    
    public init(model: AppModel, config: OutputConfig) async {
        self.context = GenerationContext(model: model, config: config)
        self.lineParser  = LineParserDuringGeneration(identifier: "-", isStatementsPrefixedWithKeyword: true, with: context)
        
        self.templateSoup  = await TemplateSoup(context: context)

        self.base_generation_dir = OutputFolder(config.output)
        self.generation_dir = self.base_generation_dir
        
        await context.fileGenerator(self)

        await setupDefaultSymbols()
    }
    
    //MARK: symbol loading
    public func loadSymbols(_ sym : Set<PreDefinedSymbols>? = nil) async throws {
        if let sym = sym {
            if let _ = sym.firstIndex(of: .typescript) {
                await self.add(modifiers: TypescriptLib.functions())
                
                if let _ = sym.firstIndex(of: .mongodb_typescript) {
                    await self.add(modifiers: MongoDB_TypescriptLib.functions(sandbox: self))
                }
            }
            
            if let _ = sym.firstIndex(of: .java) {
                await self.add(modifiers: JavaLib.functions())
            }
            
            //add GraphQL related fns
            await self.add(modifiers: GraphQLLib.functions())
            
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
        
    public func setRelativePath(_ path: String) async throws {
        if path.isNotEmpty && path != "/" {
            generation_dir = await self.base_generation_dir.relativeFolder(path)
            try await generation_dir.ensureExists()
        } else {
            generation_dir = self.base_generation_dir
            try await generation_dir.ensureExists()
        }
    }
    
    public func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) async throws -> TemplateRenderedFile? {
        if try await !context.events.canRender(filename: filename, templatename: template, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        var file = TemplateRenderedFile(filename: filename, template: template, renderer: self.templateSoup, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }
    
    public func generateFileWithData(_ filename: String, template: String, data: [String: Sendable], with pInfo: ParsedInfo) async throws -> TemplateRenderedFile? {
        if try await !context.events.canRender(filename: filename, templatename: template, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        var file = TemplateRenderedFile(filename: filename, template: template, data: data, renderer: self.templateSoup, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }
    
    public func copyFile(_ filename: String, with pInfo: ParsedInfo) async throws -> StaticFile {
        var file = await StaticFile(filename: filename, repo: templateSoup.blueprint, to: filename, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }
        
    public func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) async throws -> StaticFile {
        var file = await StaticFile(filename: filename, repo: templateSoup.blueprint, to: newFilename, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }
    
    public func copyFolder(_ foldername: String, with pInfo: ParsedInfo) async throws -> StaticFolder {
        let folder = await StaticFolder(foldername: foldername, repo: templateSoup.blueprint, to: foldername,  pInfo: pInfo)
        
        await generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try await folder.copyFiles()
        return folder
    }
    
    public func copyFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) async throws -> StaticFolder {
        let folder = await StaticFolder(foldername: foldername, repo: templateSoup.blueprint, to: newPath, pInfo: pInfo)
        
        await generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try await folder.copyFiles()
        return folder
    }
    
    public func renderFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) async throws -> RenderedFolder {
        //While rendering folder, onBeforeRenderFile is handled within the folder-rendering function
        //This is possibleas onBeforeRenderFile is part of templateSoup
        let folder = RenderedFolder(foldername: foldername, templateSoup: templateSoup, to: newPath,  pInfo: pInfo)
        
        await generation_dir.add(folder) //to be persisted in the Persist Pipeline Phase
        try await folder.renderFiles()
        return folder
    }
    
    public func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile? {
        if try await !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        var file = await PlaceHolderFile(filename: filename, repo: templateSoup.blueprint, to: filename, renderer: self.templateSoup, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }

    public func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) async throws -> PlaceHolderFile? {
        if try await !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        var file = await PlaceHolderFile(filename: filename, repo: templateSoup.blueprint, to: newFilename, renderer: self.templateSoup, pInfo: pInfo)
        
        await generation_dir.add(file) //to be persisted in the Persist Pipeline Phase
        try await file.render()
        return file
    }
}
