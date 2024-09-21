//
// TemplateSoup_EvaluationError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum TemplateSoup_EvaluationError: Error {
    case objectNotFound(Int, String)
    case unIdentifiedStmt(Int, String)
    case errorInExpression(Int, String)
    
    public var info: String {
        switch (self) {
            case .objectNotFound(let lineNo, let obj) :  return "[line \(lineNo)] object: \(obj) not found"
            case .unIdentifiedStmt(let lineNo, let line) :
            var str = """
                [Line \(lineNo) - unidentified stmt]  \(line)
                """

            var modifiedLine = line.trim()
            
            if modifiedLine.starts(with: ":") {
                modifiedLine = String(modifiedLine.dropFirst())
                modifiedLine = modifiedLine.trim()
                
                if modifiedLine.starts(with: "end") {
                    let keyword = modifiedLine.remainingLine(after: "end")
                    let msg = "MAYBE the corresp \(keyword) stmt was not detected!!!"
                    str += .newLine + msg
                }
            }
            return str
            
            case .errorInExpression(let lineNo, let expn) : return "[line \(lineNo)] expression: \(expn) error during evaluation"
        }
    }

}
