import Foundation

public struct BlueprintInfo: Codable, Sendable, Equatable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

public struct BlueprintListResult: Codable, Sendable, Equatable {
    public let blueprints: [BlueprintInfo]
    public let diagnostics: [Diagnostic]

    public init(blueprints: [BlueprintInfo], diagnostics: [Diagnostic]) {
        self.blueprints = blueprints
        self.diagnostics = diagnostics
    }
}
