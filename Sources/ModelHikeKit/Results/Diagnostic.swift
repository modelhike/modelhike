import Foundation
import ModelHike

public enum DiagnosticSeverity: String, Codable, Sendable, CaseIterable {
    case error
    case warning
    case info
    case hint

    public var rank: Int {
        switch self {
        case .error: 0
        case .warning: 1
        case .info: 2
        case .hint: 3
        }
    }

    public var icon: String {
        switch self {
        case .error: "ERROR"
        case .warning: "WARN"
        case .info: "INFO"
        case .hint: "HINT"
        }
    }
}

public enum SuggestionKind: String, Codable, Sendable {
    case didYouMean
    case availableOptions
    case note
}

public struct SourceRef: Codable, Sendable, Equatable {
    public let fileIdentifier: String
    public let lineNo: Int
    public let lineContent: String
    public let level: Int

    public init(fileIdentifier: String, lineNo: Int, lineContent: String, level: Int) {
        self.fileIdentifier = fileIdentifier
        self.lineNo = lineNo
        self.lineContent = lineContent
        self.level = level
    }
}

public struct Suggestion: Codable, Sendable, Equatable {
    public let kind: SuggestionKind
    public let message: String
    public let replacement: String?
    public let options: [String]

    public init(kind: SuggestionKind, message: String, replacement: String? = nil, options: [String] = []) {
        self.kind = kind
        self.message = message
        self.replacement = replacement
        self.options = options
    }
}

public struct Diagnostic: Codable, Sendable, Equatable {
    public let severity: DiagnosticSeverity
    public let code: DiagnosticErrorCode?
    public let message: String
    public let source: SourceRef?
    public let suggestions: [Suggestion]

    public init(
        severity: DiagnosticSeverity,
        code: DiagnosticErrorCode? = nil,
        message: String,
        source: SourceRef? = nil,
        suggestions: [Suggestion] = []
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.source = source
        self.suggestions = suggestions
    }
}

public struct DiagnosticSummary: Codable, Sendable, Equatable {
    public let total: Int
    public let errors: Int
    public let warnings: Int
    public let infos: Int
    public let hints: Int
    public let highestSeverity: DiagnosticSeverity?

    public init(diagnostics: [Diagnostic]) {
        self.total = diagnostics.count
        self.errors = diagnostics.filter { $0.severity == .error }.count
        self.warnings = diagnostics.filter { $0.severity == .warning }.count
        self.infos = diagnostics.filter { $0.severity == .info }.count
        self.hints = diagnostics.filter { $0.severity == .hint }.count
        self.highestSeverity = diagnostics.min(by: { $0.severity.rank < $1.severity.rank })?.severity
    }

    public var hasErrors: Bool { errors > 0 }
    public var hasWarnings: Bool { warnings > 0 }
}
