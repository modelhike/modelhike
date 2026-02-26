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

    /// Structured pipe-gutter logic body parsed from the DSL, if present.
    public var logic: CodeLogic?

    public var comment: String?

    /// Returns `true` when the current line is a method signature in either supported style:
    ///   - **Setext**: plain `methodName(...)` with the next line being a `~~~~~~` tilde underline.
    ///   - **Tilde**: `~ methodName(...)` prefix (no underline line required).
    public static func canParse(parser: any LineParser) async -> Bool {
        let line = await parser.currentLine()
        if isTildePrefixed(line) { return true }
        let nextLine = await parser.nextLine()
        return !nextLine.isEmpty && nextLine.hasOnly(ModelConstants.MethodUnderlineChar)
    }

    /// Parses the current line as a method signature in either supported style.
    ///
    /// **Setext style** (two DSL lines consumed, logic fenced with `~~~`):
    /// ```
    /// methodName(param: Type) : ReturnType
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// ```
    /// **Tilde style** (one DSL line consumed, logic fenced with ` ``` `):
    /// ```
    /// ~ methodName(param: Type) : ReturnType
    /// ```
    /// In both cases, any immediately following logic block is also parsed when `skipLine` is `true`.
    public static func parse(pInfo: ParsedInfo, skipLine: Bool = true) async throws -> MethodObject? {
        let line = pInfo.line
        let tilde = isTildePrefixed(line)
        let signatureLine = tilde ? String(line.dropFirst()).trim() : line

        guard let match = signatureLine.wholeMatch(of: ModelRegEx.method_Capturing) else { return nil }

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
            // Tilde style has no underline line; setext style has signature + underline.
            await pInfo.parser.skipLine(by: tilde ? 1 : 2)
            if tilde {
                await method.parseTildeLogicIfPresent(from: pInfo.parser)
            } else {
                await method.parseSetextLogicIfPresent(from: pInfo.parser)
            }
        }

        return method
    }

    /// Returns `true` when `line` begins with the `~` method prefix but is not a UIView
    /// underline (i.e. not a line composed entirely of `~` characters).
    private static func isTildePrefixed(_ line: String) -> Bool {
        line.hasPrefix(ModelConstants.Member_Method) && !line.hasOnly(ModelConstants.Member_Method)
    }

    public func returnType(from typeName: String) {
        self.returnType = TypeInfo.parse(typeName)
    }

    public func setLogic(_ value: CodeLogic) {
        self.logic = value
    }

    public var hasLogic: Bool { logic != nil && !(logic?.isEmpty ?? true) }

    /// **Setext style** — logic body starts immediately after the `~~~~~~` underline.
    /// No opening `~~~` fence; closing `~~~` is required to end the block.
    public func parseSetextLogicIfPresent(from parser: any LineParser) async {
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }
            break
        }
        guard await parser.linesRemaining else { return }
        if let logic = await CodeLogicParser.parseFenced(from: parser, closingFence: CodeLogicParser.setextFenceDelimiter) {
            self.logic = logic
        }
    }

    /// **Tilde-prefix style** — explicit ` ``` ` opening fence is required.
    /// If absent, the method has no logic body. Closing ` ``` ` is required.
    public func parseTildeLogicIfPresent(from parser: any LineParser) async {
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }
            break
        }
        guard await parser.linesRemaining else { return }
        guard await parser.currentLine() == CodeLogicParser.fenceDelimiter else { return }
        await parser.skipLine() // consume opening ```
        if let logic = await CodeLogicParser.parseFenced(from: parser, closingFence: CodeLogicParser.fenceDelimiter) {
            self.logic = logic
        }
    }

    public func append(parameter: MethodParameter) async {
        parameters.append(parameter)
    }

    public init(_ name: String, returnType: PropertyKind? = nil, pInfo: ParsedInfo) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.returnType = TypeInfo(returnType)
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
