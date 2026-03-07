//
//  ModelSnapshot_Tests.swift
//  ModelHikeTests
//

import Foundation
import Testing
@testable import ModelHike

@Suite struct ModelSnapshot_Tests {

    @Test func modelSnapshotStructure() throws {
        let container = ContainerSnapshot(
            name: "APIs",
            givenname: "APIs",
            containerType: "microservices",
            modules: [
                ModuleSnapshot(
                    name: "UserManagement",
                    givenname: "User Management",
                    objects: [
                        ObjectSnapshot(
                            name: "User",
                            givenname: "User",
                            kind: "entity",
                            properties: [
                                PropertySnapshot(name: "id", givenname: "id", typeName: "Id", required: "*")
                            ],
                            methods: [],
                            annotations: [],
                            tags: [],
                            apis: []
                        )
                    ],
                    submodules: []
                )
            ]
        )
        let model = ModelSnapshot(containers: [container])

        #expect(model.containers.count == 1)
        #expect(model.containers[0].name == "APIs")
        #expect(model.containers[0].modules.count == 1)
        #expect(model.containers[0].modules[0].objects.count == 1)
        #expect(model.containers[0].modules[0].objects[0].name == "User")
    }

    @Test func modelSnapshotEncodesToJSON() throws {
        let model = ModelSnapshot(containers: [
            ContainerSnapshot(name: "C1", givenname: "Container 1", containerType: "webApp", modules: [])
        ])
        let data = try JSONEncoder().encode(model)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["containers"] != nil)
        let containers = json?["containers"] as? [[String: Any]]
        #expect(containers?.count == 1)
        let first = containers?[0] ?? [:]
        #expect(first["name"] as? String == "C1")
    }
}
