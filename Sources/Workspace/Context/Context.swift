//
// Context.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias StringDictionary = [String: Any]

public class Context {
    public var events = CodeGenerationEvents()
    public var debugLog = ContextDebugLog()
    
    private let objManager = ObjectAttributeManager()
    public internal(set) var symbols = ContextSymbols()
    public internal(set) var paths = ContextPaths()
    
    var currentState = ContextState()

    /// Context can have different snapshots depending upon outer/inner scope they are used
    /// E.g For loop variable has a inner scope and will have a separate context
    /// If `pushSnapshot` is called, it saves a snapshot of the current context state to a stack
    /// When `popSnapshot` is called, it discards any  changes after the last snapshot, by restoring latst snapshot
    var snapshotStack : [ContextState] = []

    public func replace(variables: StringDictionary) {
        self.currentState.variables = variables
    }
    
    public func append(variables: StringDictionary) {
        variables.forEach {
            self.variables[$0.key] = $0.value
        }
    }
    
    public func pushSnapshot() {
        snapshotStack.append(currentState)
    }

    public func popSnapshot() {
        if let last = snapshotStack.popLast() {
            self.currentState = last
        }
    }
    
    public func pushCallStack(_ item: CallStackable) {
        debugLog.stack.push(item)
    }

    public func popCallStack() {
        debugLog.stack.popLast()
    }
    
    // File Generation
    public var fileGenerator : FileGeneratorProtocol!
    var generatedFiles: [ String] = []
    
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
    
    //Expression Evaluation
    fileprivate let evaluator = ExpressionEvaluator()

    public func evaluate(value: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        return try evaluator.evaluate(value: value, pInfo: pInfo)
    }
    
    public func evaluate(expression: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        return try evaluator.evaluate(expression: expression, pInfo: pInfo)
    }
    
    public func evaluateCondition(expression: String, with pInfo: ParsedInfo) throws -> Bool {
        return try evaluator.evaluateCondition(expression: expression, pInfo: pInfo)
    }
    
    public func evaluateCondition(value: Any, with pInfo: ParsedInfo) -> Bool {
        return evaluator.evaluateCondition(value: value, with: self)
    }
    
    //manage obj attributes in the context variables
    public func valueOf(variableOrObjProp name: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            return try self.objManager.getObjAttributeValue(objName: variableName, propName: attributeName, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let obj = self.variables[variableName]  {
                return obj
            } else {
                throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(variableName, pInfo)
            }
        }
    }
    
    public func setValueOf(variableOrObjProp name: String, valueExpression: String, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try objManager.setObjAttribute(objName: variableName, propName: attributeName, valueExpression: valueExpression, modifiers: modifiers, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = try self.evaluate(expression: valueExpression, with: pInfo) {
                self.variables[variableName] = body
            } else {
                self.variables.removeValue(forKey: variableName)
            }
        }
    }
    
    public func setValueOf(variableOrObjProp name: String, value: Any?, with pInfo: ParsedInfo) throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try objManager.setObjAttribute(objName: variableName, propName: attributeName, value: value, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = value {
                self.variables[variableName] = body
            } else {
                self.variables.removeValue(forKey: variableName)
            }
        }
    }
    
    public func setValueOf(variableOrObjProp name: String, body: String?, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try objManager.setObjAttribute(objName: variableName, propName: attributeName, body: body, modifiers: modifiers, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = body {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, with: pInfo) {
                    self.variables[variableName] = modifiedBody
                } else {
                    self.variables.removeValue(forKey: variableName)
                }
            } else {
                self.variables.removeValue(forKey: variableName)
            }
        }
    }
    
    //parsed model
    public let model: AppModel

    public init(paths: ContextPaths) {
        self.paths = paths
        self.model = AppModel()
    }
    
    public convenience init(data: StringDictionary) {
        self.init()
        self.replace(variables: data)
    }
    
    public convenience init() {
        let basePath = SystemFolder.documents.path / "codegen"
        let output = basePath / "output"
        
        let paths = ContextPaths(basePath: basePath, outputPath: output)
        
        self.init(paths: paths)
    }
}

public class ContextPaths {
    public var basePath: LocalPath
    public var output : OutputFolder
    
    public init(basePath: LocalPath, outputPath: LocalPath) {
        self.basePath = basePath
        self.output = OutputFolder(outputPath)
    }
    
    public init(basePath: LocalPath) {
        self.basePath = basePath
        self.output = OutputFolder(basePath / "output")
    }
    
    internal convenience init() {
        let basePath = SystemFolder.documents.path / "codegen"
        self.init(basePath: basePath)
    }
}
