//
//  ModelSnapshot.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Serializable top-level snapshot of the loaded model, used by the debug UI.
public struct ModelSnapshot: Codable, Sendable {
    public let containers: [ContainerSnapshot]

    public init(containers: [ContainerSnapshot]) {
        self.containers = containers
    }
}

/// Snapshot of one C4 container and its module tree.
public struct ContainerSnapshot: Codable, Sendable {
    public let name: String
    public let givenname: String
    public let containerType: String
    public let modules: [ModuleSnapshot]

    public init(name: String, givenname: String, containerType: String, modules: [ModuleSnapshot]) {
        self.name = name
        self.givenname = givenname
        self.containerType = containerType
        self.modules = modules
    }
}

/// Snapshot of a module/component, including nested submodules and code objects.
public struct ModuleSnapshot: Codable, Sendable {
    public let name: String
    public let givenname: String
    public let objects: [ObjectSnapshot]
    public let submodules: [ModuleSnapshot]

    public init(name: String, givenname: String, objects: [ObjectSnapshot], submodules: [ModuleSnapshot]) {
        self.name = name
        self.givenname = givenname
        self.objects = objects
        self.submodules = submodules
    }
}

/// Snapshot of a domain object, DTO, or UI object shown in the debug explorer.
public struct ObjectSnapshot: Codable, Sendable {
    public let name: String
    public let givenname: String
    public let kind: String
    public let properties: [PropertySnapshot]
    public let methods: [MethodSnapshot]
    public let annotations: [String]
    public let tags: [String]
    public let apis: [APISnapshot]

    public init(name: String, givenname: String, kind: String, properties: [PropertySnapshot], methods: [MethodSnapshot], annotations: [String], tags: [String], apis: [APISnapshot]) {
        self.name = name
        self.givenname = givenname
        self.kind = kind
        self.properties = properties
        self.methods = methods
        self.annotations = annotations
        self.tags = tags
        self.apis = apis
    }
}

/// Snapshot of one property/field on a model object.
public struct PropertySnapshot: Codable, Sendable {
    public let name: String
    public let givenname: String
    public let typeName: String
    public let required: String

    public init(name: String, givenname: String, typeName: String, required: String) {
        self.name = name
        self.givenname = givenname
        self.typeName = typeName
        self.required = required
    }
}

/// Snapshot of one method signature on a model object.
public struct MethodSnapshot: Codable, Sendable {
    public let name: String
    public let givenname: String
    public let parameters: [String]
    public let returnType: String

    public init(name: String, givenname: String, parameters: [String], returnType: String) {
        self.name = name
        self.givenname = givenname
        self.parameters = parameters
        self.returnType = returnType
    }
}

/// Snapshot of one API attached to a model object.
public struct APISnapshot: Codable, Sendable {
    public let name: String
    public let type: String

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}
