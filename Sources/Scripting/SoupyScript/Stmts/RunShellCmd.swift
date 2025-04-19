//
//  RunShellCmdStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct RunShellCmdStmt: LineTemplateStmt, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "run-shell-cmd"

    public private(set) var CommandToRun: String = ""

    nonisolated(unsafe)
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

    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex) else { return false }

        let (_, expn) = match.output

        self.CommandToRun = expn

        return true
    }

    public func execute(with ctx: Context) async throws -> String? {
        guard CommandToRun.isNotEmpty else { return nil }

        if await ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }

        print("⚙️  Running the shell command...")
        let fullPath = await ctx.config.output.path / ctx.workingDirectoryString
        let options = Shell.Options(workingDirectory: fullPath.string)
        let result = Shell.execute(command: CommandToRun, options: options)

        if result.failed {
            if let stderr = result.stderr, stderr.isNotEmpty {
                print(stderr)
                print("")
            }
            print("❌ Failed to finish the shell command!!!")
        } else {
            if let stdout = result.stdout, stdout.isNotEmpty {
                print(stdout)
                print("")
            }

            print("✅ Finished the shell command...")
        }

        return nil
    }

    public var debugDescription: String {
        let str = """
            RUN SHELL CMD stmt (level: \(pInfo.level))
            - expn: \(self.CommandToRun)

            """

        return str
    }

    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }

    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) { pInfo in
        RunShellCmdStmt(pInfo)
    }
}
