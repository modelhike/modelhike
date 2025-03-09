//
//  AnnnounceStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class AnnnounceStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "announce"

    public private(set) var Expression: String = ""

    let stmtRegex = Regex {
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

    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex) else { return false }

        let (_, expn) = match.output

        self.Expression = expn

        return true
    }

    public override func execute(with ctx: Context) throws -> String? {
        guard Expression.isNotEmpty else { return nil }

        //see if it is an object
        if let expn = try? ctx.evaluate(value: Expression, with: pInfo) {
            print("🔈 \(expn)")
        } else {
            print("🔈🎈[Line no: \(lineNo)] - nothing to announce")
        }

        return nil
    }

    public var debugDescription: String {
        let str = """
            ANNOUNCE stmt (level: \(pInfo.level))
            - expn: \(self.Expression)

            """

        return str
    }

    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }

    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) { pInfo in
        AnnnounceStmt(pInfo)
    }
}
