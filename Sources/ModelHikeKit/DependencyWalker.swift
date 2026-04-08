import Foundation
import ModelHike

enum DependencyWalker {
    static func references(to entity: EntityDetail, in explanation: ExplanationResult) -> [Reference] {
        let dependents = dependentsOf(entity.name, in: explanation)
        return dependents.map { dependent in
            Reference(
                containerName: "",
                moduleName: "",
                entityName: dependent.entityName,
                propertyName: dependent.location,
                referenceType: dependent.rawValue
            )
        }
    }

    static func dependents(of entityName: String, in explanation: ExplanationResult) -> [Dependent] {
        dependentsOf(entityName, in: explanation)
    }

    /// Walk the live `AppModel` actor graph for dependency types not captured in the snapshot:
    /// applied constraints, default expressions, method parameter types, module expressions, and named constraints.
    static func liveModelDependents(of entityName: String, in model: AppModel) async -> [Dependent] {
        let normalized = SnapshotMapper.normalizeName(entityName)
        var dependents: [Dependent] = []

        let containers = await model.containers.snapshot()
        for container in containers {
            let types = await container.types
            for type in types {
                let typeName = await type.givenname

                // Property-level: appliedConstraints and appliedDefaultExpression
                let properties = await type.properties
                for property in properties {
                    let propName = await property.givenname

                    let constraints = await property.appliedConstraints
                    for constraint in constraints {
                        if SnapshotMapper.normalizeName(constraint) == normalized {
                            dependents.append(Dependent(
                                entityName: typeName,
                                location: "property \(propName) applied constraint",
                                referenceKind: "appliedConstraint",
                                rawValue: constraint
                            ))
                        }
                    }

                    if let defaultExpr = await property.appliedDefaultExpression {
                        if SnapshotMapper.normalizeName(defaultExpr) == normalized {
                            dependents.append(Dependent(
                                entityName: typeName,
                                location: "property \(propName) default expression",
                                referenceKind: "defaultExpression",
                                rawValue: "@\(defaultExpr)"
                            ))
                        }
                    }
                }

                // Method parameter types
                let methods = await type.methods
                for method in methods {
                    let methodName = await method.givenname
                    let params = await method.parameters
                    for param in params {
                        let paramTypeName = param.type.typeNameString_ForDebugging()
                        if param.type.isSameAs(entityName) {
                            dependents.append(Dependent(
                                entityName: typeName,
                                location: "method \(methodName) parameter \(param.name)",
                                referenceKind: "methodParamType",
                                rawValue: paramTypeName
                            ))
                        }
                    }
                }
            }

            // Module-level expressions and named constraints
            let modules = await container.components.snapshot()
            for module in modules {
                let moduleName = await module.givenname
                await collectModuleLevelDependents(
                    in: module,
                    moduleName: moduleName,
                    entityName: entityName,
                    normalized: normalized,
                    dependents: &dependents
                )
            }
        }

        return deduplicateDependents(dependents)
    }

    private static func collectModuleLevelDependents(
        in module: C4Component,
        moduleName: String,
        entityName: String,
        normalized: String,
        dependents: inout [Dependent]
    ) async {
        let expressions = await module.expressions
        for expr in expressions {
            let exprName = await expr.givenname
            if await expr.type.isSameAs(entityName) {
                dependents.append(Dependent(
                    entityName: "[module] \(moduleName)",
                    location: "expression \(exprName) type",
                    referenceKind: "moduleExpression",
                    rawValue: await expr.type.typeNameString_ForDebugging()
                ))
            }
        }

        let constraintItems = await module.namedConstraints.snapshot()
        for constraint in constraintItems {
            if let name = constraint.name, SnapshotMapper.normalizeName(name) == normalized {
                dependents.append(Dependent(
                    entityName: "[module] \(moduleName)",
                    location: "named constraint",
                    referenceKind: "namedConstraint",
                    rawValue: name
                ))
            }
        }
    }

    private static func deduplicateDependents(_ dependents: [Dependent]) -> [Dependent] {
        var seen = Set<String>()
        var result: [Dependent] = []
        for dep in dependents {
            let key = [dep.entityName, dep.location, dep.referenceKind, dep.rawValue].joined(separator: "|")
            if seen.insert(key).inserted {
                result.append(dep)
            }
        }
        return result
    }

    /// Merge snapshot-based and live-model dependents, deduplicating by entity+location+kind.
    static func mergeDependents(_ snapshotDeps: [Dependent], _ liveDeps: [Dependent]) -> [Dependent] {
        var all = snapshotDeps
        let existingKeys = Set(snapshotDeps.map {
            [$0.entityName, $0.location, $0.referenceKind].joined(separator: "|")
        })
        for dep in liveDeps {
            let key = [dep.entityName, dep.location, dep.referenceKind].joined(separator: "|")
            if !existingKeys.contains(key) {
                all.append(dep)
            }
        }
        return all.sorted {
            [$0.entityName, $0.location, $0.referenceKind].joined(separator: "|")
                < [$1.entityName, $1.location, $1.referenceKind].joined(separator: "|")
        }
    }

    private static func dependentsOf(_ entityName: String, in explanation: ExplanationResult) -> [Dependent] {
        let candidates = Set([SnapshotMapper.normalizeName(entityName)])
        var dependents: [Dependent] = []

        for container in explanation.containers {
            for module in container.modules {
                collectDependents(in: module, candidates: candidates, dependents: &dependents)
            }
        }

        return dependents.sorted {
            [$0.entityName, $0.location, $0.referenceKind].joined(separator: "|")
                < [$1.entityName, $1.location, $1.referenceKind].joined(separator: "|")
        }
    }

    static func computeBreakingChanges(
        dependents: [Dependent],
        changeKind: String,
        oldName: String,
        newName: String? = nil
    ) -> [BreakingChange] {
        dependents.map { dependent in
            let hint: String
            switch changeKind {
            case "rename":
                let newVal = newName ?? "???"
                hint = "Rename '\(oldName)' to '\(newVal)' in \(dependent.location) of '\(dependent.entityName)' (currently '\(dependent.rawValue)')"
            case "remove":
                hint = "Remove or replace reference to '\(oldName)' in \(dependent.location) of '\(dependent.entityName)' (currently '\(dependent.rawValue)')"
            default:
                hint = "Update \(dependent.location) of '\(dependent.entityName)' (references '\(oldName)')"
            }

            return BreakingChange(
                entityName: dependent.entityName,
                location: dependent.location,
                currentValue: dependent.rawValue,
                fixHint: hint
            )
        }
    }

    private static func collectDependents(
        in module: ModuleSummary,
        candidates: Set<String>,
        dependents: inout [Dependent]
    ) {
        for object in module.objects {
            // Property type references
            for property in object.properties {
                let normalized = normalizedReferenceType(from: property.typeName)
                if candidates.contains(normalized) {
                    dependents.append(
                        Dependent(
                            entityName: object.displayName,
                            location: "property \(property.displayName)",
                            referenceKind: "propertyType",
                            rawValue: property.typeName
                        )
                    )
                }
                // Also check @Target portion if present
                let targetMatch = extractTargetReference(from: property.typeName)
                if let target = targetMatch, candidates.contains(SnapshotMapper.normalizeName(target)) {
                    dependents.append(
                        Dependent(
                            entityName: object.displayName,
                            location: "property \(property.displayName) constraint target",
                            referenceKind: "constraintRef",
                            rawValue: targetMatch ?? property.typeName
                        )
                    )
                }
            }

            // Method return type references
            for method in object.methods {
                let normalized = normalizedReferenceType(from: method.returnType)
                if candidates.contains(normalized) {
                    dependents.append(
                        Dependent(
                            entityName: object.displayName,
                            location: "method \(method.displayName) return type",
                            referenceKind: "methodReturnType",
                            rawValue: method.returnType
                        )
                    )
                }
            }

            // Annotation references
            for annotation in object.annotations {
                let normalized = SnapshotMapper.normalizeName(annotation)
                if candidates.contains(normalized) {
                    dependents.append(
                        Dependent(
                            entityName: object.displayName,
                            location: "annotation",
                            referenceKind: "annotation",
                            rawValue: annotation
                        )
                    )
                }
            }

            // Tag references
            for tag in object.tags {
                let normalized = SnapshotMapper.normalizeName(tag)
                if candidates.contains(normalized) {
                    dependents.append(
                        Dependent(
                            entityName: object.displayName,
                            location: "tag",
                            referenceKind: "tag",
                            rawValue: tag
                        )
                    )
                }
            }
        }

        for submodule in module.submodules {
            collectDependents(in: submodule, candidates: candidates, dependents: &dependents)
        }
    }

    private static func normalizedReferenceType(from rawType: String) -> String {
        var type = rawType.trimmingCharacters(in: .whitespacesAndNewlines)

        if let atIndex = type.lastIndex(of: "@") {
            type = String(type[type.index(after: atIndex)...])
        }

        if let dotIndex = type.firstIndex(of: ".") {
            type = String(type[..<dotIndex])
        }

        if let bracketIndex = type.firstIndex(of: "[") {
            type = String(type[..<bracketIndex])
        }

        return SnapshotMapper.normalizeName(type)
    }

    private static func extractTargetReference(from rawType: String) -> String? {
        let type = rawType.trimmingCharacters(in: .whitespacesAndNewlines)

        if let atIndex = type.lastIndex(of: "@") {
            let target = String(type[type.index(after: atIndex)...])
            if let dotIndex = target.firstIndex(of: ".") {
                return String(target[..<dotIndex])
            }
            return target
        }

        return nil
    }
}
