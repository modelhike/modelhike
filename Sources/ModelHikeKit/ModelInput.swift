import Foundation

public enum ModelInput: Sendable, Equatable {
    case content(String)
    case file(String)
    case directory(String)

    var modelContent: String? {
        switch self {
        case .content(let content):
            content
        case .file(let path):
            try? String(contentsOfFile: path, encoding: .utf8)
        case .directory:
            nil
        }
    }
}

struct NamedTextFile: Sendable, Equatable {
    let identifier: String
    let content: String
}

struct ResolvedModelInput: Sendable, Equatable {
    let domainModels: [NamedTextFile]
    let commonModels: [NamedTextFile]
    let inlineConfig: NamedTextFile?
    let basePath: String
}
