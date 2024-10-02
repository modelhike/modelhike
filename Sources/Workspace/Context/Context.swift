//
// Context.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias StringDictionary = [String: Any]

public class Context {
    public var debugLog = ContextDebugLog()
    
    private var objManager: ObjectAttributeManager!
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

    public func evaluate(value: String, lineNo: Int) throws -> Optional<Any> {
        return try evaluator.evaluate(value: value, lineNo: lineNo, with: self)
    }
    
    public func evaluate(expression: String, lineNo: Int) throws -> Optional<Any> {
        return try evaluator.evaluate(expression: expression, lineNo: lineNo, with: self)
    }
    
    public func evaluateCondition(expression: String, lineNo: Int) throws -> Bool {
        return try evaluator.evaluateCondition(expression: expression, lineNo: lineNo, with: self)
    }
    
    public func evaluateCondition(value: Any, lineNo: Int) -> Bool {
        return evaluator.evaluateCondition(value: value, with: self)
    }
    
    //manage obj attributes in the context variables
    public func valueOf(objName: String, propName attributeName: String) -> Optional<Any> {
        return self.objManager.getObjAttributeValue(objName: objName, attributeName: attributeName)
    }
    
    public func valueOf(variableOrObjProp name: String) -> Optional<Any> {
        let split = name.split(separator: ".")
        if split.count > 1 { //object attribute
            let variableName = "\(split[0])"
            let attributeName = "\(split[1])"

            return self.objManager!.getObjAttributeValue(objName: variableName, attributeName: attributeName)
            
        } else { // object only
            let variableName = "\(split[0])"

            if let obj = self.variables[variableName]  {
                return obj
            }
        }
        
        return nil
    }
    
    public func setObjProp(objName: String, propName: String, valueExpression: String, modifiers: [ModifierInstance], lineNo: Int) throws {
        try objManager.setObjAttribute(objName: objName, attributeName: propName, valueExpression: valueExpression, modifiers: modifiers, lineNo: lineNo, with: self)
    }
    
    public func setObjProp(objName: String, propName: String, body: String?, modifiers: [ModifierInstance], lineNo: Int) throws {
        try objManager.setObjAttribute(objName: objName, attributeName: propName, body: body, modifiers: modifiers, lineNo: lineNo, with: self)
    }
    
    //parsed model
    public let model: AppModel

    public init(paths: ContextPaths) {
        self.paths = paths
        self.model = AppModel()

        defer {
            self.objManager = ObjectAttributeManager(context: self)
        }
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
