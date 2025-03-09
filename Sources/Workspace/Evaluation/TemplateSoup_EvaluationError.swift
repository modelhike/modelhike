//
// TemplateSoup_EvaluationError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum TemplateSoup_EvaluationError: ErrorWithMessageAndParsedInfo {
    case objectNotFound(String, ParsedInfo)
    case unIdentifiedStmt(ParsedInfo)
    case errorInExpression(String, ParsedInfo)
    case workingDirectoryNotSet(ParsedInfo)
    case templateDoesNotExist(String, ParsedInfo)
    case templateReadingError(String, ParsedInfo)
    case scriptFileDoesNotExist(String, ParsedInfo)
    case scriptFileReadingError(String, ParsedInfo)
    
    public var info: String {
        switch (self) {
        case .workingDirectoryNotSet(_) : return "Working Directory not set!!!"
        case .templateDoesNotExist(let templateName, _) : return "Template '\(templateName)' not found!!!"
        case .templateReadingError(let templateName, _) : return "Template '\(templateName)' reading error!!!"
        case .scriptFileDoesNotExist(let scriptName, _) : return "ScriptFile '\(scriptName)' not found!!!"
        case .scriptFileReadingError(let scriptName, _) : return "ScriptFile '\(scriptName)' reading error!!!"
        case .objectNotFound(let obj, _) :  return "object: \(obj) not found"
        
        case .unIdentifiedStmt(let pInfo) :
            var str = "unidentified stmt >>  \(pInfo.line)"

            var modifiedLine = pInfo.line.trim()
            
            if modifiedLine.starts(with: TemplateConstants.stmtKeyWord) {
                modifiedLine = String(modifiedLine.dropFirst())
                modifiedLine = modifiedLine.trim()
                
                if modifiedLine.starts(with: TemplateConstants.templateEndKeyword) {
                    let keyword = modifiedLine.remainingLine(after: TemplateConstants.templateEndKeywordWithHyphen)
                    let msg = "MAYBE the corresp '\(keyword)' stmt was not detected!!!"
                    str += .newLine + msg
                }
            }
            return str
            
        case .errorInExpression(let expn, _) : return "expression: \(expn) error during evaluation"
        }
    }
    
    public var pInfo: ParsedInfo {
        return switch (self) {
        case .workingDirectoryNotSet(let pInfo) : pInfo
        case .templateDoesNotExist(_, let pInfo) : pInfo
        case .templateReadingError(_, let pInfo) : pInfo
        case .scriptFileDoesNotExist(_, let pInfo) : pInfo
        case .scriptFileReadingError(_, let pInfo) : pInfo
        case .objectNotFound(_, let pInfo) : pInfo
        case .unIdentifiedStmt(let pInfo) : pInfo
        case .errorInExpression(_, let pInfo) : pInfo
        }
    }

}
