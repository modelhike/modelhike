import Foundation

public struct ValidationResult: Codable, Sendable, Equatable {
    public let valid: Bool
    public let diagnostics: [Diagnostic]
    public let summary: DiagnosticSummary

    public init(valid: Bool, diagnostics: [Diagnostic]) {
        self.valid = valid
        self.diagnostics = diagnostics
        self.summary = DiagnosticSummary(diagnostics: diagnostics)
    }
}
