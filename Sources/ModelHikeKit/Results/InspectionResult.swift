import Foundation

public typealias EntityDetail = EntitySummary

public struct Reference: Codable, Sendable, Equatable {
    public let containerName: String
    public let moduleName: String
    public let entityName: String
    public let propertyName: String
    public let referenceType: String

    public init(containerName: String, moduleName: String, entityName: String, propertyName: String, referenceType: String) {
        self.containerName = containerName
        self.moduleName = moduleName
        self.entityName = entityName
        self.propertyName = propertyName
        self.referenceType = referenceType
    }
}

public struct InspectionResult: Codable, Sendable, Equatable {
    public let entity: EntityDetail?
    public let references: [Reference]
    public let generatedArtifacts: [String]
    public let diagnostics: [Diagnostic]

    public init(entity: EntityDetail?, references: [Reference], generatedArtifacts: [String], diagnostics: [Diagnostic]) {
        self.entity = entity
        self.references = references
        self.generatedArtifacts = generatedArtifacts
        self.diagnostics = diagnostics
    }
}
