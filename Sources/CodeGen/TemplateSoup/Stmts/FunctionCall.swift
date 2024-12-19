//
// FunctionCallStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class FunctionCallStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "call"

    public private(set) var FnName: String = ""
    public private(set) var Args: String = ""
    
    let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        CommonRegEx.functionInvocation_namedArgs_Capturing
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fnName, argsString) = match.output

        self.FnName = fnName
        self.Args = argsString
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard FnName.isNotEmpty else { return nil }
                
        let args = Args.getArray_UsingNamedArgsPattern()

        if let templateFn  = ctx.templateFunctions[FnName] {
            let body = try templateFn.execute(args: args, with: ctx)
            return body
        } else {
            throw TemplateSoup_ParsingError.templateFunctionNotFound(lineNo, FnName)
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
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in FunctionCallStmt(pInfo) }
}

