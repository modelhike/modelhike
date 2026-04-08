import Foundation

public struct FixAction: Codable, Sendable, Equatable {
    public let code: String
    public let message: String
    public let action: String
    public let line: Int

    public init(code: String, message: String, action: String, line: Int) {
        self.code = code
        self.message = message
        self.action = action
        self.line = line
    }
}

public struct FixResult: Codable, Sendable, Equatable {
    public let fixed: Bool
    public let model: String?       // null if no model provided/fixable
    public let applied: [FixAction]
    public let remaining: [Diagnostic]
    public let diagnostics: [Diagnostic]

    public init(fixed: Bool, model: String?, applied: [FixAction], remaining: [Diagnostic], diagnostics: [Diagnostic]) {
        self.fixed = fixed
        self.model = model
        self.applied = applied
        self.remaining = remaining
        self.diagnostics = diagnostics
    }
}
