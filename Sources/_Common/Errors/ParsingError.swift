//
// ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParsingError: ErrorWithMessageAndParsedInfo {
    case invalidLine(ParsedInfo, ErrorWithMessage)
    //case invalidLineWithInfo_HavingLineno(ParsedInfo, ErrorWithMessage)
    case invalidLineWithoutErr(String, ParsedInfo)
    case unrecognisedParsingDirective(String, ParsedInfo)
    case invalidParsingDirective(ParsedInfo)

    public var info: String {
        switch (self) {
            case .invalidLine(_, let err) :
                return err.info
//            case .invalidLineWithInfo_HavingLineno(let pInfo, let err) :
//            return "🐞🐞 \(pInfo.identifier) >> \(err.info)"
            case .invalidLineWithoutErr(let info, _) :
                return info
            case .unrecognisedParsingDirective(let directiveName, _) :
                return "Unrecognised Parsing Directive '\(directiveName)'"
            case .invalidParsingDirective(let pInfo) :
                return "invalid Parsing Directive '\(pInfo.line)"
        }
    }
    
    public var pInfo: ParsedInfo {
        return switch (self) {
            case .invalidLine(let pInfo, _) : pInfo
            //case .invalidLineWithInfo_HavingLineno(let pInfo, let err) : pInfo
            case .invalidLineWithoutErr(_, let pInfo) : pInfo
            case .unrecognisedParsingDirective(_, let pInfo) : pInfo
            case .invalidParsingDirective(let pInfo) : pInfo
        }
    }

}
