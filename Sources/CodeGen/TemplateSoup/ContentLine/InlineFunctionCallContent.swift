//
// InlineFunctionCallContent.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class InlineFunctionCallContent: ContentLineItem {
    let fnCallLine : String
    let level: Int
    let lineNo: Int
    let ctx: Context
    var fnCall : FunctionCallStmt!
    
    fileprivate func parseLine(_ line: String) throws {
        let stmt = FunctionCallStmt()
        
        if try stmt.matchLine(line: line, level: level, with: ctx) {
            self.fnCall = stmt
        } else {
            throw TemplateSoup_ParsingError.invalidExpression(lineNo, line)
        }
    }
    
    public func execute(with ctx: Context) throws -> String? {
        if fnCall != nil {
            if var result = try fnCall.execute(with: ctx) {
                //Spaces are to be automaticaly removed, when the function is called inline
                result = result.spaceless() // remove all spaces in the body
                return result
            }
        }
            
        return nil
    }
    
    public var debugDescription: String {
        if let fnCall = self.fnCall {
            let str =  """
        INLINE CALL Function (level: \(level))
        - fn name: \(fnCall.FnName)
        - args: \(fnCall.Args)
        
        """
            
            return str
        } else {
            let str =  """
        INLINE CALL Function (level: \(level))
        !!!! Invalid Syntax !!!!!
        
        """
            
            return str
        }
    }
    
    public init(fnCallLine: String, lineNo: Int, level: Int, with ctx: Context) throws {
        self.fnCallLine = fnCallLine
        self.lineNo = lineNo
        self.level = level
        self.ctx = ctx
        
        try parseLine(fnCallLine.trim())
    }
}
