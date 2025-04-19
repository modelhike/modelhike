//
//  FunctionCallStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct FunctionCallStmt: LineTemplateStmt, CallStackable, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "call"

    public private(set) var FnName: String = ""
    public private(set) var Args: String = ""
    
    nonisolated(unsafe)
    let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        CommonRegEx.functionInvocation_namedArgs_Capturing
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fnName, argsString) = match.output

        self.FnName = fnName
        self.Args = argsString
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard FnName.isNotEmpty else { return nil }
                
        let args = Args.getArray_UsingNamedArgsPattern()

        if let templateFn  = await ctx.templateFunctions[FnName] {
            await ctx.pushCallStack(self)
            
            let body = try await templateFn.execute(args: args, pInfo: pInfo, with: ctx)
            
            await ctx.popCallStack()
            return body
        } else {
            throw TemplateSoup_ParsingError.templateFunctionNotFound(FnName, pInfo)
        }
    }
    
    public var debugDescription: String {
        let str =  """
        CALL Function stmt (level: \(pInfo.level))
        - fn name: \(self.FnName)
        - args: \(self.Args)
        
        """
                
        return str
    }
    
    public var callStackItem: CallStackItem { CallStackItem(self, pInfo: pInfo) }
    
    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in FunctionCallStmt(pInfo) }
}

