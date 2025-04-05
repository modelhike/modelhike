//
//  C4Component_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Component_Wrap : ObjectWrapper {
    public let item: C4Component
    let model : AppModel
    
    public var attribs: Attributes { get async {
        await item.attribs
    }}

    public var types: [CodeObject_Wrap] { get async {
        await item.types.compactMap({ CodeObject_Wrap($0)})
    }}
    
    public var embeddedTypes: [CodeObject_Wrap] { get async {
        var result: [CodeObject_Wrap] = []
        
        for type in await item.types {
            if await type.dataType == .embeddedType {
                result.append(CodeObject_Wrap(type))
            }
        }
        
        return result
    }}
    
    public var entities: [CodeObject_Wrap] { get async {
        var result: [CodeObject_Wrap] = []
        
        for type in await item.types {
            if await type.dataType == .entity {
                result.append(CodeObject_Wrap(type))
            }
        }
        
        return result
    }}
    
    public var dtos: [CodeObject_Wrap] {
        get async {
            var result: [CodeObject_Wrap] = []
            
            for type in await item.types {
                if await type.dataType == .dto, let dto = type as? DtoObject {
                    result.append(CodeObject_Wrap(dto))
                }
            }
            
            return result
        }
    }
    
    public var entitiesAndDtos : [CodeObject_Wrap] { get async {
        var list = await entities
        await list.append(contentsOf: dtos)
        return list
    }}
    
    public var apis: [API_Wrap] {
        get async {
            var result: [API_Wrap] = []
            
            for type in await item.types {
                let apis = await type.getAPIs()
                let converted = apis.compactMap { API_Wrap($0) }
                result.append(contentsOf: converted)
            }
            
            return result
        }
    }
    
    public var pushDataApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            if ($0.item.type == .pushData ||
                $0.item.type == .pushDataList
            ) { return $0 } else {return nil}    }) }}
    
    public var mutationApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            if ($0.item.type == .create ||
                $0.item.type == .update ||
                $0.item.type == .delete ||
                $0.item.type == .mutationUsingCustomLogic
            ) { return $0 } else {return nil}
        }) }}
    
    public var queryApis : [API_Wrap] { get async {
        await self.apis.compactMap({
            if ($0.item.type == .getById ||
                $0.item.type == .getByCustomProperties ||
                $0.item.type == .list ||
                $0.item.type == .listByCustomProperties
            ) { return $0 } else {return nil}    }) }}
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable {
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
        let attribs = await item.attribs
        if await attribs.has(propname) {
            return await attribs.get(propname)
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





