import Foundation

public struct PreflightCheck: Codable, Sendable, Equatable {
    public let name: String
    public let status: String  // "pass" | "fail" | "warn"
    public let detail: String
    public let fixHint: String

    public init(name: String, status: String, detail: String, fixHint: String) {
        self.name = name
        self.status = status
        self.detail = detail
        self.fixHint = fixHint
    }
}

public struct PreflightResult: Codable, Sendable, Equatable {
    public let ready: Bool
    public let checks: [PreflightCheck]
    public let recommendation: String
    public let diagnostics: [Diagnostic]

    public init(ready: Bool, checks: [PreflightCheck], recommendation: String, diagnostics: [Diagnostic]) {
        self.ready = ready
        self.checks = checks
        self.recommendation = recommendation
        self.diagnostics = diagnostics
    }
}
