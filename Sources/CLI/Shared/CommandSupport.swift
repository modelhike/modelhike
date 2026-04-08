import ArgumentParser
import Foundation
import ModelHikeKit

enum CommandSupport {
    static func printAndExit(_ output: String, code: ToolExitCode) throws {
        print(output)
        if code != .success {
            throw code.commandExitCode
        }
    }

    static func exitCode(for diagnostics: [Diagnostic], defaultCode: ToolExitCode = .success) -> ToolExitCode {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .validationErrors
        }
        if diagnostics.contains(where: { $0.severity == .warning }) {
            return .validationWarnings
        }
        return defaultCode
    }

    static func errorOutput(for error: Error) -> String {
        let payload = [
            "error": [
                "message": String(describing: error),
            ],
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{\"error\":{\"message\":\"\(String(describing: error))\"}}"
    }
}
