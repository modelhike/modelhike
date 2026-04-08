import Foundation
import ModelHike

enum SnapshotMapper {
    static func map(_ snapshot: ModelSnapshot, diagnostics: [Diagnostic]) -> ExplanationResult {
        let containers = snapshot.containers.map(map)
        return ExplanationResult(
            containers: containers,
            diagnostics: diagnostics,
            summary: summarize(containers)
        )
    }

    static func findEntity(named query: String, in explanation: ExplanationResult) -> (EntityDetail?, String?, String?) {
        let normalizedQuery = normalizeName(query)

        for container in explanation.containers {
            for module in container.modules {
                if let match = findEntity(named: normalizedQuery, in: module, containerName: container.displayName) {
                    return match
                }
            }
        }

        return (nil, nil, nil)
    }

    private static func findEntity(named normalizedQuery: String, in module: ModuleSummary, containerName: String) -> (EntityDetail?, String?, String?)? {
        for object in module.objects {
            let candidates = [normalizeName(object.name), normalizeName(object.displayName)]
            if candidates.contains(normalizedQuery) {
                return (object, containerName, module.displayName)
            }
        }

        for submodule in module.submodules {
            if let match = findEntity(named: normalizedQuery, in: submodule, containerName: containerName) {
                return match
            }
        }

        return nil
    }

    private static func map(_ container: ContainerSnapshot) -> ContainerSummary {
        ContainerSummary(
            name: container.name,
            displayName: container.givenname,
            containerType: container.containerType,
            modules: container.modules.map(map)
        )
    }

    private static func map(_ module: ModuleSnapshot) -> ModuleSummary {
        ModuleSummary(
            name: module.name,
            displayName: module.givenname,
            objects: module.objects.map(map),
            submodules: module.submodules.map(map)
        )
    }

    private static func map(_ object: ObjectSnapshot) -> EntitySummary {
        EntitySummary(
            name: object.name,
            displayName: object.givenname,
            kind: object.kind,
            properties: object.properties.map {
                PropertySummary(
                    name: $0.name,
                    displayName: $0.givenname,
                    typeName: $0.typeName,
                    required: $0.required
                )
            },
            methods: object.methods.map {
                MethodSummary(
                    name: $0.name,
                    displayName: $0.givenname,
                    parameters: $0.parameters,
                    returnType: $0.returnType
                )
            },
            annotations: object.annotations,
            tags: object.tags,
            apis: object.apis.map { ApiSummary(name: $0.name, type: $0.type) }
        )
    }

    private static func summarize(_ containers: [ContainerSummary]) -> ModelSummary {
        let moduleCount = containers.reduce(0) { $0 + countModules(in: $1.modules) }
        let entityCount = containers.reduce(0) { $0 + countEntities(in: $1.modules) }
        let propertyCount = containers.reduce(0) { $0 + countProperties(in: $1.modules) }
        let methodCount = containers.reduce(0) { $0 + countMethods(in: $1.modules) }
        let apiCount = containers.reduce(0) { $0 + countApis(in: $1.modules) }

        return ModelSummary(
            containerCount: containers.count,
            moduleCount: moduleCount,
            entityCount: entityCount,
            propertyCount: propertyCount,
            methodCount: methodCount,
            apiCount: apiCount
        )
    }

    private static func countModules(in modules: [ModuleSummary]) -> Int {
        modules.reduce(0) { partial, module in
            partial + 1 + countModules(in: module.submodules)
        }
    }

    private static func countEntities(in modules: [ModuleSummary]) -> Int {
        modules.reduce(0) { partial, module in
            partial + module.objects.count + countEntities(in: module.submodules)
        }
    }

    private static func countProperties(in modules: [ModuleSummary]) -> Int {
        modules.reduce(0) { partial, module in
            partial
                + module.objects.reduce(0) { $0 + $1.properties.count }
                + countProperties(in: module.submodules)
        }
    }

    private static func countMethods(in modules: [ModuleSummary]) -> Int {
        modules.reduce(0) { partial, module in
            partial
                + module.objects.reduce(0) { $0 + $1.methods.count }
                + countMethods(in: module.submodules)
        }
    }

    private static func countApis(in modules: [ModuleSummary]) -> Int {
        modules.reduce(0) { partial, module in
            partial
                + module.objects.reduce(0) { $0 + $1.apis.count }
                + countApis(in: module.submodules)
        }
    }

    static func normalizeName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}
