//
//  AnnnounceStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct AnnnounceStmt: LineTemplateStmt {
    public var state: LineTemplateStmtState

    static let START_KEYWORD = "announce"

    public private(set) var Expression: String = ""

    nonisolated(unsafe)
    private let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: {
            String($0)
        }
        ZeroOrMore(.whitespace)

        CommonRegEx.comments
    }

    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex) else { return false }

        let (_, expn) = match.output

        self.Expression = expn

        return true
    }

    public func execute(with ctx: Context) async throws -> String? {
        guard Expression.isNotEmpty else { return nil }

        //see if it is an object
        if let expn = try? await ctx.evaluate(value: Expression, with: pInfo) {
            print("🔈 \(expn)")
        } else {
            print("🔈🎈[Line no: \(lineNo)] - nothing to announce")
        }

        return nil
    }

    public var debugDescription: String { get async {
        let str = """
            ANNOUNCE stmt (level: \(pInfo.level))
            - expn: \(self.Expression)
            
            """
        
        return str
    }}

    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }

    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) { pInfo in
        AnnnounceStmt(pInfo)
    }
}
