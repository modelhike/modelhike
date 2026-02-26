//
//  CodeLogicParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Parses fenced logic blocks from a `LineParser` into a `CodeLogic` tree.
///
/// Logic is written inside a fenced block, similar to Markdown code fences:
///
/// ```
/// ~~~                           ← opening fence (optional for setext methods)
/// return x                      ← depth-1 line statement
/// |> IF condition               ← depth-1 block opener
/// | return amount               ← depth-2 line statement (child of IF)
/// | |> FOR items                ← depth-2 block opener
/// | | return item               ← depth-3 line statement (child of FOR)
/// |> ELSE                       ← depth-1 block opener (sibling of IF)
/// | return default              ← depth-2 line statement
/// ~~~                           ← closing fence
/// ```
///
/// **Depth rules inside the fence:**
/// - Block openers (`|> KEYWORD`) — `N ≥ 1` pipes then `>` then the keyword; tree depth = N.
/// - Line statements (no `>`)    — `N ≥ 0` pipes then the keyword; tree depth = N + 1.
/// - Block keyword case is flexible (IF / if / If all parse to `.if`).
///
/// Parsing stops when the closing ` ``` ` is encountered, at a recognised DSL-element
/// prefix character (`*`, `-`, `_`, `@`, `#`, `~`, `+`, `=`), or at end of input.
public enum CodeLogicParser {

    // MARK: - Public constants

    /// Backtick fence used by tilde-prefix methods (` ``` ` — opening required, closing required).
    public static let fenceDelimiter = "```"

    /// Tilde fence used by setext methods (`~~~` — opening optional, closing required).
    public static let setextFenceDelimiter = "~~~"

    // MARK: - Public API

    /// Parses a raw logic string (already inside a fence) into a `CodeLogic` tree.
    ///
    /// Convenience entry-point for tests — the input is treated as if it were already
    /// between the opening and closing fences. No fence delimiter is expected.
    public static func parse(dslString: String) async -> CodeLogic? {
        let ctx = LoadContext(config: PipelineConfig())
        let parser = LineParserDuringLoad(
            string: dslString,
            identifier: "logic",
            isStatementsPrefixedWithKeyword: false,
            with: ctx
        )
        return await parseFenced(from: parser)
    }

    /// Reads lines from `parser` as fenced logic content and returns a `CodeLogic` tree.
    ///
    /// Call this **after** the opening fence has already been consumed (or in the implicit-start
    /// case for setext methods where the opening fence is optional).
    ///
    /// - Parameter closingFence: The delimiter that ends the logic block.
    ///   Use `fenceDelimiter` (` ``` `) for tilde-prefix methods and
    ///   `setextFenceDelimiter` (`~~~`) for setext methods.
    ///
    /// Terminates on:
    /// - A line equal to `closingFence` — consumed and parsing ends successfully.
    /// - A line whose first non-whitespace character is a recognised DSL prefix
    ///   (`*`, `-`, `_`, `@`, `#`, `~`, `+`, `=`) — not consumed, returns what was parsed.
    /// - End of input — returns what was parsed.
    public static func parseFenced(from parser: any LineParser, closingFence: String = fenceDelimiter) async -> CodeLogic? {
        var rawLines: [ParsedLogicLine] = []

        while await parser.linesRemaining {
            let line = await parser.currentLine()

            // Closing fence — consume and stop
            if line == closingFence {
                await parser.skipLine()
                break
            }

            // Blank lines inside a fence are skipped
            if line.isEmpty {
                await parser.skipLine()
                continue
            }

            if let parsed = parseLine(line) {
                rawLines.append(parsed)
            }
            await parser.skipLine()
        }

        guard !rawLines.isEmpty else { return nil }

        let stream = LineStream(rawLines)
        return CodeLogic(statements: await buildStatements(from: stream, baseDepth: 1))
    }

    // MARK: - Line parsing

    /// Flat representation of a single parsed logic line before tree assembly.
    private struct ParsedLogicLine {
        let depth: Int
        let keyword: String
        let expression: String
    }

    /// Parses a single line of fenced logic content.
    ///
    /// **Block openers** — `|> KEYWORD expression` (pipes, then `>`, then the keyword in any case):
    /// - `|> IF condition`   depth-1 block opener
    /// - `||> FOR item in x` depth-2 block opener
    /// - `| |> WHILE cond`   depth-2 (spaces between pipes allowed)
    /// - Require `N ≥ 1` pipes; `depth = N`.
    ///
    /// **Line statements** — `keyword expression` with optional leading pipes:
    /// - `return x`          depth-1 (N=0)
    /// - `|return x`         depth-2 (N=1)
    /// - `| return x`        depth-2 (space after pipe allowed)
    /// - `depth = N + 1`.
    private static func parseLine(_ line: String) -> ParsedLogicLine? {
        var line = line

        // Count depth pipes, allowing optional spaces between them for readability.
        // "|> IF", "| |> FOR", "||> WHILE" are all valid.
        var N = 0
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            if c == "|" {
                N += 1
                i = line.index(after: i)
            } else if c == " " || c == "\t" {
                i = line.index(after: i)
            } else {
                break
            }
        }
        line = String(line[i...])

        guard !line.isEmpty else {
            return ParsedLogicLine(depth: N + 1, keyword: "", expression: "")
        }

        // Block opener: "> KEYWORD expression"
        let isBlock = line.hasPrefix(">")
        if isBlock { guard N >= 1 else { return nil } }

        let content = isBlock ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
        let parts = content.splitOnFirstWhitespace()
        return ParsedLogicLine(
            depth: isBlock ? N : N + 1,
            keyword: parts.first.lowercased(),
            expression: parts.second
        )
    }

    // MARK: - Tree assembly

    private final class LineStream: @unchecked Sendable {
        private let lines: [ParsedLogicLine]
        private var index: Int = 0

        var current: ParsedLogicLine? { index < lines.count ? lines[index] : nil }

        init(_ lines: [ParsedLogicLine]) { self.lines = lines }
        func advance() { index += 1 }
    }

    private static func buildStatements(from stream: LineStream, baseDepth: Int) async -> [CodeLogicStmt] {
        var result: [CodeLogicStmt] = []

        while let line = stream.current, line.depth == baseDepth {
            stream.advance()

            let kind = CodeLogicStmtKind.parse(line.keyword)
            let stmt = CodeLogicStmt(kind: kind, expression: line.expression)

            if let next = stream.current, next.depth > baseDepth {
                let children = await buildStatements(from: stream, baseDepth: next.depth)
                await stmt.setChildren(children)
            }

            result.append(stmt)
        }

        return result
    }
}

// MARK: - String helper

private extension String {
    func splitOnFirstWhitespace() -> (first: String, second: String) {
        guard let range = rangeOfCharacter(from: .whitespaces) else {
            return (self, "")
        }
        let first = String(self[startIndex..<range.lowerBound])
        let second = String(self[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (first, second)
    }
}
