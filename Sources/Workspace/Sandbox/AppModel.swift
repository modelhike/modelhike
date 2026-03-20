//
//  AppModel.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor AppModel {
    let types = ParsedTypesCache()
    public internal(set) var commonModel = C4ComponentList()
    private var modules = C4ComponentList()
    public private(set) var containers = C4ContainerList()
    public private(set) var isModelsLoaded = false

    public func resolveAndLinkItems(with ctx: LoadContext) async throws {

        //resolve modules
        await containers.forEach { container in
            for unresolvedMember in await container.unresolvedMembers {
                if let module = await module(named: unresolvedMember.name) {
                    await container.append(module)
                    await container.remove(unResolved: unresolvedMember)
                }
            }
        }
        
        await commonModel.addTypesTo(model: types)
        await containers.addTypesTo(model: types)
        
        // Process mixins and DTO-derived properties first.
        try await containers.forEach { container in
            
            for type in await container.types {
                try await ParserUtil.extractMixins(for: type, with: ctx)
                
                if let dto = type as? DtoObject {
                    try await dto.populateDerivedProperties()
                }
            }
        }

        // Canonicalize custom type names after all properties have been materialized.
        // e.g., the propeties for Dtos are populated only in the above steps
        await containers.forEach { container in
            for type in await container.types {
                for prop in await type.properties {
                    if await prop.type.isCustomType {
                        if let obj = await ctx.model.types.get(for: prop.type.objectString()) {
                            // Change the typename according to the retrieved object; this
                            // correctly fixes the type name even if the given name used a
                            // different casing or contained spaces.
                            await prop.typeKind(.customType(obj.name))
                        }
                    }
                }
            }
        }

        // Resolve all reference-like `Ref@Target.field` types against the loaded model so they store
        // canonical target names and, when a field is specified, the actual field type.
        await containers.forEach { container in
            for type in await container.types {
                for prop in await type.properties {
                    await resolveReferenceTargets(for: prop, in: ctx)
                }
            }
        }
    }
    
    public func container(named name: String) async -> C4Container? {
        return await containers.first(where: {await $0.name == name})
    }
    
    public func module(named name: String) async -> C4Component? {
        return await modules.first(where: {
            let itemname = await $0.name
            let itemGivenname = await $0.givenname
            return itemname == name || itemGivenname == name
        })
    }
    
    public func appendToCommonModel(contentsOf modelSpace: ModelSpace) async {
        let modelContainers = await modelSpace.containers.snapshot()
        let modelModules = await modelSpace.modules.snapshot()

        for container in modelContainers {
            await commonModel.append(contentsOf: container)
        }
        
        for module in modelModules {
            await commonModel.append(module)
        }
    }
    
    public func append(contentsOf modelSpace: ModelSpace) async {
        let modelContainers = await modelSpace.containers.snapshot()
        let modelModules = await modelSpace.modules.snapshot()

        for container in modelContainers {
            await containers.append(container)
        }
        
        for module in modelModules {
            await modules.append(module)
        }
    }
    
    internal func isModelsLoaded(_ value: Bool) {
        self.isModelsLoaded = value
    }
    
    public init() {
        
    }

    private func resolveReferenceTargets(for property: Property, in ctx: LoadContext) async {
        let kind = await property.type.kind
        guard let targets = kind.referenceTargets, targets.isEmpty == false else {
            return
        }

        // Resolve each parsed reference target against the loaded model so later consumers
        // can work with canonical type/property names instead of the raw DSL spelling.
        var resolvedTargets: [ReferenceTarget] = []
        resolvedTargets.reserveCapacity(targets.count)

        for var reference in targets {
            // If the target type cannot be found yet, keep the parsed reference as-is.
            guard let targetObject = await ctx.model.types.get(for: reference.targetName) else {
                resolvedTargets.append(reference)
                continue
            }

            // Store both the canonical target name and the resolved object handle. The name is
            // what gets rendered/compared; the object lets downstream code inspect the target
            // without resolving it a second time.
            reference.targetName = await targetObject.name
            reference.targetObject = targetObject

            // A reference may also point at a specific property, e.g. Ref@Department.id.
            // When present, canonicalize that property name and keep the resolved property
            // itself so callers can inspect the full type later instead of only a type name.
            if let fieldName = reference.fieldName,
               let targetProperty = await targetObject.getProp(fieldName) {
                reference.fieldName = await targetProperty.name
                reference.fieldProperty = targetProperty
            }

            resolvedTargets.append(reference)
        }

        // Preserve the original reference kind (single, multi, extended, etc.) while swapping
        // in the resolved payloads.
        await property.typeKind(kind.replacingReferenceTargets(resolvedTargets))
    }
}
