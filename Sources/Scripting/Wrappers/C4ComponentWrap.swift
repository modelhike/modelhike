//
//  C4Component_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Component_Wrap : ObjectWrapper {
    public let item: C4Component
    let model : AppModel
    
    public var attribs: Attributes { item.attribs }

    public var types: [CodeObject_Wrap] { get async {
        await item.types.compactMap({ CodeObject_Wrap($0)})
    }}
    
    public var embeddedTypes: [CodeObject_Wrap] { get async {
        await item.types.compactMap({
            if await $0.dataType == .embeddedType {CodeObject_Wrap($0)} else {nil}})
    }}
    
    public var entities: [CodeObject_Wrap] { get async {
        await item.types.compactMap({
            if await $0.dataType == .entity {CodeObject_Wrap($0)} else {nil}})
    }}
    
    public var dtos: [CodeObject_Wrap] { get async {
        await item.types.compactMap({
            if await $0.dataType == .dto, let dto = $0 as? DtoObject {CodeObject_Wrap(dto)} else {nil}})
    }}
    
    public var entitiesAndDtos : [CodeObject_Wrap] { get async {
        var list = await entities
        await list.append(contentsOf: dtos)
        return list
    }}
    
    public var apis: [API_Wrap] {
        get async {
            var result: [API_Wrap] = []
            
            for type in await item.types {
                let apis = await type.getAPIs().snapshot()
                let converted = await apis.compactMap { API_Wrap($0) }
                result.append(contentsOf: converted)
            }
            
            return result
        }
    }
    
    public var pushDataApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            let itemtype = await $0.item.type
            
            if (itemtype == .pushData ||
                itemtype == .pushDataList
            ) { return $0 } else {return nil}    })
    }}
    
    public var mutationApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            let itemtype = await $0.item.type
            
            if (itemtype == .create ||
                itemtype == .update ||
                itemtype == .delete ||
                itemtype == .mutationUsingCustomLogic
            ) { return $0 } else {return nil}
        })
    }}
    
    public var queryApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            let itemtype = await $0.item.type

            if (itemtype == .getById ||
                itemtype == .getByCustomProperties ||
                itemtype == .list ||
                itemtype == .listByCustomProperties
            ) { return $0 } else {return nil}    })
    }}
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        let value: Sendable = switch propname {
        case "name": await item.name
        case "types" : await types
        case "embedded-types" : await embeddedTypes
        case "has-embedded-types" : await embeddedTypes.count != 0
        case "entities" : await entities
        case "has-entities" : await entities.count != 0
        case "dtos" : await dtos
        case "has-dtos" : await dtos.count != 0
        case "entities-and-dtos" : await entitiesAndDtos
        case "push-apis" : await pushDataApis
        case "has-push-apis" : await pushDataApis.count != 0
        case "query-apis" : await queryApis
        case "has-query-apis" : await queryApis.count != 0
        case "mutation-apis" : await mutationApis
        case "has-mutation-apis" : await mutationApis.count != 0
        case "has-any-apis" : await apis.count != 0
        default:
            //nothing found; so check in module attributes
            try await resolveFallbackProperty(propname: propname, pInfo: pInfo)
        }
        
        return value
    }
    
    private func resolveFallbackProperty(propname: String, pInfo: ParsedInfo) async throws -> Sendable {
        let attribs = item.attribs
        if await attribs.has(propname) {
            return await attribs[propname]
        } else {
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
    }
    
    public var debugDescription: String { get async {
        await item.debugDescription
    }}

    public init(_ item: C4Component, model: AppModel ) {
        self.item = item
        self.model = model
    }
}





