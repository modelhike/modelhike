//
//  Context.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

fileprivate let working_dir_var : String = "working_dir"

public protocol Context : AnyObject, Actor {
    var config : OutputConfig {get}
    var debugLog: ContextDebugLog {get set}
    var events: CodeGenerationEvents {get}
    var currentState: ContextState {get set}
    var variables: WorkingMemory {get}
    var symbols: ContextSymbols {get}
    var templateFunctions: TemplateFunctionMap {get}
    var snapshotStack : SnapshotStack {get}
    var objManager: ObjectAttributeManager {get}
    var evaluator: ExpressionEvaluator {get}

    func evaluate(expression: String, with pInfo: ParsedInfo) throws -> Optional<Any>
    func evaluateCondition(expression: String, with pInfo: ParsedInfo) throws -> Bool
}

public extension Context {
    var variables: WorkingMemory {
        get { currentState.variables }
    }
    
    var debugInfo: DebugDictionary {
        get { currentState.debugInfo }
        set { currentState.debugInfo = newValue }
    }
    
    var templateFunctions: TemplateFunctionMap  {
        get { currentState.templateFunctions }
    }
    
    var loopIsFirst: Bool { get async { await variables["@loop.first"] as? Bool ?? false }}
    var loopIsLast: Bool { get async { await variables["@loop.last"] as? Bool ?? false }}
    
    var workingDirectoryString: String { get async { await variables[working_dir_var] as? String ?? "" }}
    var workingDirectory: LocalPath { get async { await config.output.path / workingDirectoryString }}

    @discardableResult
    internal func setWorkingDirectory(_ foldername: String) async -> Bool {
        await variables.set(working_dir_var, value: foldername)
        return true
    }
    
    func isWorkingDirectoryVariable(_ name: String) -> Bool {
        return name == working_dir_var
    }
    
    func append(variables vars: StringDictionary) async {
        for (key, value) in vars {
            await self.variables.set(key, value: value)
        }
    }

    func append(variables vars: WorkingMemory) async {
        for (key, value) in await vars.snapshot() {
            await self.variables.set(key, value: value)
        }
    }
    
    func replace(variables: StringDictionary) async {
        await self.currentState.variables.replace(variables: variables)
    }
    
    func replace(variables: WorkingMemory) async {
        await self.currentState.variables.replace(variables: variables)
    }
    
    func pushSnapshot() {
        snapshotStack.append(currentState)
    }

    func popSnapshot() {
        if let last = snapshotStack.popLast() {
            self.currentState = last
        }
    }
    
    func pushCallStack(_ item: CallStackable) async {
        await debugLog.stack.push(item)
    }

    func popCallStack() async {
        await debugLog.stack.popLast()
    }
    
    func evaluate(value: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        return try await evaluator.evaluate(value: value, pInfo: pInfo)
    }
    
    func evaluate(expression: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        return try await evaluator.evaluate(expression: expression, pInfo: pInfo)
    }
    
    func evaluateCondition(expression: String, with pInfo: ParsedInfo) async throws -> Bool {
        return try await evaluator.evaluateCondition(expression: expression, pInfo: pInfo)
    }
    
    func evaluateCondition(value: Sendable, with pInfo: ParsedInfo) async -> Bool {
        return await evaluator.evaluateCondition(value: value, with: self)
    }
    
    //manage obj attributes in the context variables
    func valueOf(variableOrObjProp name: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            return try await self.objManager.getObjAttributeValue(objName: variableName, propName: attributeName, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let obj = await self.variables[variableName]  {
                return obj
            } else {
                throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(variableName, pInfo)
            }
        }
    }
    
    func setValueOf(variableOrObjProp name: String, valueExpression: String, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) async throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try await objManager.setObjAttribute(objName: variableName, propName: attributeName, valueExpression: valueExpression, modifiers: modifiers, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = try await self.evaluate(expression: valueExpression, with: pInfo) {
                await self.variables.set(variableName, value: body)
            } else {
                await self.variables.removeValue(forKey: variableName)
            }
        }
    }
    
    func setValueOf(variableOrObjProp name: String, value: Sendable?, with pInfo: ParsedInfo) async throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try await objManager.setObjAttribute(objName: variableName, propName: attributeName, value: value, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = value {
                await self.variables.set(variableName, value: body)
            } else {
                await self.variables.removeValue(forKey: variableName)
            }
        }
    }
    
    func setValueOf(variableOrObjProp name: String, body: String?, modifiers: [ModifierInstance] = [], with pInfo: ParsedInfo) async throws {
        
        if let dotIndex = name.firstIndex(of: ".") { //object attribute
            let beforeDot = String(name[..<dotIndex])
            let afterDot = String(name[name.index(after: dotIndex)...])

            let variableName = beforeDot
            let attributeName = afterDot

            try await objManager.setObjAttribute(objName: variableName, propName: attributeName, body: body, modifiers: modifiers, with: pInfo)
            
        } else { // object only
            let variableName = name

            if let body = body {
                if let modifiedBody = try await Modifiers.apply(to: body, modifiers: modifiers, with: pInfo) {
                    await self.variables.set(variableName, value: modifiedBody)
                } else {
                    await self.variables.removeValue(forKey: variableName)
                }
            } else {
                await self.variables.removeValue(forKey: variableName)
            }
        }
    }
}
