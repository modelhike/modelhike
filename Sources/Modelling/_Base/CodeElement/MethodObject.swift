//
// Method.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class MethodObject : CodeMember {
    public var attribs = Attributes()
    public var tags = Tags()

    public var name: String
    public var givenname: String
    public var returnType : TypeInfo
    public var parameters: [MethodParameter] = []
    
    public var body : StringTemplate
    
    public var comment: String?
    
    public static func parse(with pctx: ParsingContext, skipLine: Bool = true) throws -> MethodObject? {
        let originalLine = pctx.line
        let firstWord = pctx.firstWord
        
        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.method_Capturing)                                                    else { return nil }
        
        let (_, methodName, arguments , returnType, tagString) = match.output
        
        let givenName = methodName.trim()
        
        let method = MethodObject(givenName)
        
        let matches = arguments.matches(of: CommonRegEx.namedParameters_Capturing)
        
        matches.forEach( { match in
            let (_, name, typeName) = match.output
            let type = TypeInfo.parse(typeName)
            method.parameters.append( MethodParameter(name: name, type: type) )
        })
        
        if let returnType = returnType {
            method.returnType = TypeInfo.parse(returnType)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: method, from: tagString)
        }
        
        if skipLine {
            pctx.parser.skipLine()
        }
        
        return method
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Member_Method : return true
            default : return false
        }
    }
    
    public init(_ name: String, returnType: PropertyKind? = nil) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.returnType = TypeInfo(returnType)
        self.body = StringTemplate("")
    }
    
    public init(_ name: String, returnType: PropertyKind? = nil, @StringConvertibleBuilder _ body: () -> [StringConvertible]) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.returnType = TypeInfo(returnType)
        self.body = StringTemplate(body)
    }
}

public struct MethodParameter {
    let name: String
    let type: TypeInfo
    
    public init(name: String, type: TypeInfo) {
        self.name = name
        self.type = type
    }
}


public enum ReturnType {
    case void, int, double, bool, string, customType(String)
}
