//
// Context.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

fileprivate let working_dir_var : String = "working_dir"

public protocol Context : AnyObject {
    var config : PipelineConfig {get}
    var debugLog: ContextDebugLog {get}
    var events: CodeGenerationEvents {get}
    var currentState: ContextState {get set}
    var variables: StringDictionary {get set}
    var symbols: ContextSymbols {get}
    var templateFunctions: [String: TemplateFunctionContainer] {get set}
    var snapshotStack : [ContextState] {get set}
    var objManager: ObjectAttributeManager {get}
    var evaluator: ExpressionEvaluator {get}

    func evaluate(expression: String, with pInfo: ParsedInfo) throws -> Optional<Any>
    func evaluateCondition(expression: String, with pInfo: ParsedInfo) throws -> Bool
}

public extension Context {
    var variables: StringDictionary {
        get { currentState.variables }
        set { currentState.variables = newValue }
    }

    var debugInfo: DebugDictionary {
        get { currentState.debugInfo }
        set { currentState.debugInfo = newValue }
    }
    
    var templateFunctions: [String: TemplateFunctionContainer]  {
        get { currentState.templateFunctions }
        set { currentState.templateFunctions = newValue }
    }
    
    var loopIsFirst: Bool { variables["__first"] as? Bool ?? false}
    var loopIsLast: Bool { variables["__last"] as? Bool ?? false}
    
    var workingDirectoryString: String { variables[working_dir_var] as? String ?? "" }
    var workingDirectory: LocalPath { config.output.path / workingDirectoryString }

    @discardableResult
    internal func setWorkingDirectory(_ foldername: String) -> Bool {
        variables[working_dir_var] = foldername
        return true
    }
    
    func isWorkingDirectoryVariable(_ name: String) -> Bool {
        return name == working_dir_var
    }
    
    func replace(variables: StringDictionary) {
        self.currentState.variables = variables
    }
    
    func pushSnapshot() {
        snapshotStack.append(currentState)
    }

    func popSnapshot() {
        if let last = snapshotStack.popLast() {
            self.currentState = last
        }
    }
    
    func pushCallStack(_ item: CallStackable) {
        debugLog.stack.push(item)
    }

    func popCallStack() {
        debugLog.stack.popLast()
    }
    
    func evaluate(value: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        return try evaluator.evaluate(value: value, pInfo: pInfo)
    }
    
    func evaluate(expression: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        return try evaluator.evaluate(expression: expression, pInfo: pInfo)
    }
    
    func evaluateCondition(expression: String, with pInfo: ParsedInfo) throws -> Bool {
        return try evaluator.evaluateCondition(expression: expression, pInfo: pInfo)
    }
    
    func evaluateCondition(value: Any, with pInfo: ParsedInfo) -> Bool {
        return evaluator.evaluateCondition(value: value, with: self)
    }
    
    //manage obj attributes in the context variables
    func valueOf(variableOrObjProp name: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        
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
    
    func setValueOf(variableOrObjProp name: String, valueExpression: String, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) throws {
        
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
    
    func setValueOf(variableOrObjProp name: String, value: Any?, with pInfo: ParsedInfo) throws {
        
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
    
    func setValueOf(variableOrObjProp name: String, body: String?, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) throws {
        
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
}
