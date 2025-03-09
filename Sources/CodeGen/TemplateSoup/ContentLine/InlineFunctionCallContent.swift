//
//  InlineFunctionCallContent.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class InlineFunctionCallContent: ContentLineItem {
    let fnCallLine : String
    let level: Int
    public let pInfo: ParsedInfo
    var fnCall : FunctionCallStmt!
    
    fileprivate func parseLine(_ line: String) throws {
        let stmt = FunctionCallStmt(pInfo)
        
        if try stmt.matchLine(line: line) {
            self.fnCall = stmt
        } else {
            throw TemplateSoup_ParsingError.invalidExpression(line, pInfo)
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
    
    public init(fnCallLine: String, pInfo: ParsedInfo, level: Int) throws {
        self.fnCallLine = fnCallLine
        self.pInfo = pInfo
        self.level = level
        
        try parseLine(fnCallLine.trim())
    }
}
