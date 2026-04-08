import Foundation

public struct TypeInfo: Codable, Sendable, Equatable {
    public let name: String
    public let kind: String  // "entity" | "enum" | "value-object"
    public let module: String
    public let container: String

    public init(name: String, kind: String, module: String, container: String) {
        self.name = name
        self.kind = kind
        self.module = module
        self.container = container
    }
}

public struct TypeListResult: Codable, Sendable, Equatable {
    public let types: [TypeInfo]
    public let diagnostics: [Diagnostic]

    public init(types: [TypeInfo], diagnostics: [Diagnostic]) {
        self.types = types
        self.diagnostics = diagnostics
    }
}
