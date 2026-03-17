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
    ///   - **Setext**: plain `methodName(...)` or paramless `methodName` with the next line being a method underline.
    ///   - **Tilde**: `~ methodName(...)` or paramless `~ methodName` (no underline line required).
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
    /// ```
    /// methodName
    /// ----------
    /// ```
    /// **Tilde style** (one DSL line consumed, logic fenced with ` ``` `, `'''`, or `"""`):
    /// ```
    /// ~ methodName(param: Type) : ReturnType
    /// ```
    /// ```
    /// ~ methodName
    /// ```
    /// In both cases, any immediately following logic block is also parsed when `skipLine` is `true`.
    public static func parse(pInfo: ParsedInfo, skipLine: Bool = true) async throws -> MethodObject? {
        let line = pInfo.line
        let tilde = isTildePrefixed(line)
        let signatureLine = tilde ? String(line.dropFirst()).trim() : line

        guard let signature = parseSignature(signatureLine) else { return nil }

        let givenName = signature.name.trim()

        let method = MethodObject(givenName, pInfo: pInfo)

        let matches = signature.arguments.matches(of: CommonRegEx.namedParameters_Capturing)

        for match in matches {
            let (_, name, typeName) = match.output
            let type = TypeInfo.parse(typeName)
            await method.append(parameter: MethodParameter(name: name, type: type))
        }

        if let returnType = signature.returnType {
            await method.returnType(from: returnType)
        }

        if let attributeString = signature.attributeString {
            await ParserUtil.populateAttributes(for: method, from: attributeString)
        }

        //check if has tags
        if let tagString = signature.tagString {
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

    private struct ParsedMethodSignature {
        let name: String
        let arguments: String
        let returnType: String?
        let attributeString: String?
        let tagString: String?
    }

    private static func parseSignature(_ line: String) -> ParsedMethodSignature? {
        if let match = line.wholeMatch(of: ModelRegEx.method_Capturing) {
            let (_, methodName, arguments, returnType, attributeString, tagString) = match.output
            return ParsedMethodSignature(
                name: methodName,
                arguments: arguments,
                returnType: returnType,
                attributeString: attributeString,
                tagString: tagString
            )
        }

        guard let match = line.wholeMatch(of: ModelRegEx.methodParamless_Capturing) else {
            return nil
        }

        let (_, methodName, returnType, attributeString, tagString) = match.output
        return ParsedMethodSignature(
            name: methodName,
            arguments: "",
            returnType: returnType,
            attributeString: attributeString,
            tagString: tagString
        )
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

    /// **Tilde-prefix style** — an explicit opening fence is required.
    /// Supported fence styles: ` ``` `, `'''`, or `"""`.
    /// If none is present, the method has no logic body.
    /// The closing fence must match the opening fence.
    public func parseTildeLogicIfPresent(from parser: any LineParser) async {
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }
            break
        }
        guard await parser.linesRemaining else { return }
        guard let fence = CodeLogicParser.tildeFenceDelimiter(for: await parser.currentLine()) else { return }
        await parser.skipLine() // consume opening fence
        if let logic = await CodeLogicParser.parseFenced(from: parser, closingFence: fence) {
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
