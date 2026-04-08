import Foundation
import ModelHike
import ModelHikeKit

enum InlineInputResolver {
    static func resolveModelInput(_ value: String) throws -> ModelInput {
        if looksLikeInlineModelContent(value) {
            return .content(value)
        }
        guard FileManager.default.fileExists(atPath: value) else {
            throw InlineInputError.fileNotFound(value)
        }
        return .file(value)
    }

    static func resolveInlineBlueprint(_ value: String) throws -> InlineBlueprintSnapshot {
        let jsonString: String
        if value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            jsonString = value
        } else {
            guard FileManager.default.fileExists(atPath: value) else {
                throw InlineInputError.fileNotFound(value)
            }
            jsonString = try String(contentsOfFile: value, encoding: .utf8)
        }
        return try InlineBlueprintSnapshot.fromJSON(jsonString)
    }

    private static func looksLikeInlineModelContent(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("===") || trimmed.contains(String.newLine)
    }
}

enum InlineInputError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Input path was not found: \(path)"
        }
    }
}
