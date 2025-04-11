//
//  MethodObject.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor MethodObject: CodeMember {
    public let pInfo: ParsedInfo
    public var attribs = Attributes()
    public var tags = Tags()

    public var name: String
    public var givenname: String
    public var returnType: TypeInfo
    public var parameters: [MethodParameter] = []

    public var body: StringTemplate

    public var comment: String?

    public static func parse(pInfo: ParsedInfo, skipLine: Bool = true) async throws -> MethodObject? {
        let originalLine = pInfo.line
        let firstWord = pInfo.firstWord

        let line = originalLine.remainingLine(after: firstWord)  //remove first word

        guard let match = line.wholeMatch(of: ModelRegEx.method_Capturing) else { return nil }

        let (_, methodName, arguments, returnType, tagString) = match.output

        let givenName = methodName.trim()

        let method = MethodObject(givenName, pInfo: pInfo)

        let matches = arguments.matches(of: CommonRegEx.namedParameters_Capturing)

        for match in matches {
            let (_, name, typeName) = match.output
            let type = TypeInfo.parse(typeName)
            await method.append(parameter: MethodParameter(name: name, type: type))
        }

        if let returnType = returnType {
            await method.returnType(from: returnType)
        }

        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: method, from: tagString)
        }

        if skipLine {
            await pInfo.parser.skipLine()
        }

        return method
    }

    public func returnType(from typeName: String) {
        self.returnType = TypeInfo.parse(typeName)
    }
    
    
    public func append(parameter: MethodParameter) async {
        parameters.append(parameter)
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
        case ModelConstants.Member_Method: return true
        default: return false
        }
    }

    public init(_ name: String, returnType: PropertyKind? = nil, pInfo: ParsedInfo) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.returnType = TypeInfo(returnType)
        self.body = StringTemplate("")
        self.pInfo = pInfo
    }

    public init(
        _ name: String, returnType: PropertyKind? = nil, pInfo: ParsedInfo,
        @StringConvertibleBuilder _ body: () -> [StringConvertible]
    ) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.returnType = TypeInfo(returnType)
        self.body = StringTemplate(body)
        self.pInfo = pInfo
    }
}

public struct MethodParameter: Sendable {
    let name: String
    let type: TypeInfo

    public init(name: String, type: TypeInfo) {
        self.name = name
        self.type = type
    }
}

public enum ReturnType: Sendable {
    case void, int, double, bool, string
    case customType(String)
}
