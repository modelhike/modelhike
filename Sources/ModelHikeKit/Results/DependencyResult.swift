import Foundation

public struct Dependent: Codable, Sendable, Equatable {
    public let entityName: String
    public let location: String          // e.g., "property owner", "method findOwner return type", "annotation", "tag"
    public let referenceKind: String     // "propertyType" | "methodReturnType" | "annotation" | "tag" | "constraintRef" | "defaultExpression" | "moduleInclusion"
    public let rawValue: String          // the original string that matched (e.g., "User", "User[1..*]")

    public init(entityName: String, location: String, referenceKind: String, rawValue: String) {
        self.entityName = entityName
        self.location = location
        self.referenceKind = referenceKind
        self.rawValue = rawValue
    }
}

public struct BreakingChange: Codable, Sendable, Equatable {
    public let entityName: String
    public let location: String
    public let currentValue: String
    public let fixHint: String          // e.g., "Rename 'User' to 'Customer' in property 'owner' of 'Order'"

    public init(entityName: String, location: String, currentValue: String, fixHint: String) {
        self.entityName = entityName
        self.location = location
        self.currentValue = currentValue
        self.fixHint = fixHint
    }
}

public struct DependencyResult: Codable, Sendable, Equatable {
    public let entity: String
    public let dependents: [Dependent]
    public let breakingChanges: [BreakingChange]
    public let diagnostics: [Diagnostic]

    public init(entity: String, dependents: [Dependent], breakingChanges: [BreakingChange], diagnostics: [Diagnostic]) {
        self.entity = entity
        self.dependents = dependents
        self.breakingChanges = breakingChanges
        self.diagnostics = diagnostics
    }
}
