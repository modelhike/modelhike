import Foundation
import ModelHikeKit

enum InputResolver {
    static func resolve(input: String?) throws -> ModelInput {
        guard let input, !input.isEmpty else {
            return .directory(FileManager.default.currentDirectoryPath)
        }

        if input == "-" {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            guard let content = String(data: data, encoding: .utf8) else {
                throw InputResolverError.invalidUTF8
            }
            return .content(content)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) else {
            throw InputResolverError.notFound(input)
        }

        if isDirectory.boolValue {
            return .directory(input)
        }

        return .file(input)
    }
}

enum InputResolverError: LocalizedError {
    case invalidUTF8
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            return "Standard input is not valid UTF-8 text."
        case .notFound(let path):
            return "Input path was not found: \(path)"
        }
    }
}
