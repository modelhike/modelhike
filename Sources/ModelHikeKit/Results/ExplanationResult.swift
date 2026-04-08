import Foundation

public struct ModelSummary: Codable, Sendable, Equatable {
    public let containerCount: Int
    public let moduleCount: Int
    public let entityCount: Int
    public let propertyCount: Int
    public let methodCount: Int
    public let apiCount: Int

    public init(
        containerCount: Int,
        moduleCount: Int,
        entityCount: Int,
        propertyCount: Int,
        methodCount: Int,
        apiCount: Int
    ) {
        self.containerCount = containerCount
        self.moduleCount = moduleCount
        self.entityCount = entityCount
        self.propertyCount = propertyCount
        self.methodCount = methodCount
        self.apiCount = apiCount
    }
}

public struct ApiSummary: Codable, Sendable, Equatable {
    public let name: String
    public let type: String

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

public struct PropertySummary: Codable, Sendable, Equatable {
    public let name: String
    public let displayName: String
    public let typeName: String
    public let required: String

    public init(name: String, displayName: String, typeName: String, required: String) {
        self.name = name
        self.displayName = displayName
        self.typeName = typeName
        self.required = required
    }
}

public struct MethodSummary: Codable, Sendable, Equatable {
    public let name: String
    public let displayName: String
    public let parameters: [String]
    public let returnType: String

    public init(name: String, displayName: String, parameters: [String], returnType: String) {
        self.name = name
        self.displayName = displayName
        self.parameters = parameters
        self.returnType = returnType
    }
}

public struct EntitySummary: Codable, Sendable, Equatable {
    public let name: String
    public let displayName: String
    public let kind: String
    public let properties: [PropertySummary]
    public let methods: [MethodSummary]
    public let annotations: [String]
    public let tags: [String]
    public let apis: [ApiSummary]

    public init(
        name: String,
        displayName: String,
        kind: String,
        properties: [PropertySummary],
        methods: [MethodSummary],
        annotations: [String],
        tags: [String],
        apis: [ApiSummary]
    ) {
        self.name = name
        self.displayName = displayName
        self.kind = kind
        self.properties = properties
        self.methods = methods
        self.annotations = annotations
        self.tags = tags
        self.apis = apis
    }
}

public struct ModuleSummary: Codable, Sendable, Equatable {
    public let name: String
    public let displayName: String
    public let objects: [EntitySummary]
    public let submodules: [ModuleSummary]

    public init(name: String, displayName: String, objects: [EntitySummary], submodules: [ModuleSummary]) {
        self.name = name
        self.displayName = displayName
        self.objects = objects
        self.submodules = submodules
    }
}

public struct ContainerSummary: Codable, Sendable, Equatable {
    public let name: String
    public let displayName: String
    public let containerType: String
    public let modules: [ModuleSummary]

    public init(name: String, displayName: String, containerType: String, modules: [ModuleSummary]) {
        self.name = name
        self.displayName = displayName
        self.containerType = containerType
        self.modules = modules
    }
}

public struct ExplanationResult: Codable, Sendable, Equatable {
    public let containers: [ContainerSummary]
    public let diagnostics: [Diagnostic]
    public let summary: ModelSummary

    public init(containers: [ContainerSummary], diagnostics: [Diagnostic], summary: ModelSummary) {
        self.containers = containers
        self.diagnostics = diagnostics
        self.summary = summary
    }
}
