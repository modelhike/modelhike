import Foundation

public struct GenerationSummary: Codable, Sendable, Equatable {
    public let fileCount: Int

    public init(fileCount: Int) {
        self.fileCount = fileCount
    }
}

public struct GeneratedFile: Codable, Sendable, Equatable {
    public let path: String
    public let content: String

    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

public struct GenerationResult: Codable, Sendable, Equatable {
    public let files: [GeneratedFile]
    public let tree: String
    public let diagnostics: [Diagnostic]
    public let persisted: Bool
    public let outputDirectory: String?
    public let summary: GenerationSummary

    public init(
        files: [GeneratedFile],
        tree: String,
        diagnostics: [Diagnostic],
        persisted: Bool = false,
        outputDirectory: String? = nil
    ) {
        self.files = files
        self.tree = tree
        self.diagnostics = diagnostics
        self.persisted = persisted
        self.outputDirectory = outputDirectory
        self.summary = GenerationSummary(fileCount: files.count)
    }
}
