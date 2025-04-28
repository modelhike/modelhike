//
//  API_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor API_Wrap : ObjectWrapper {
    public let item: API
    
    public var attribs: Attributes { get async { await item.attribs }}
    
    public var queryParams:  [APIParam_Wrap] { get async {
        await item.queryParams.compactMap({ APIParam_Wrap($0) })
    }}
    
    public var customProperties : [TypeProperty_Wrap] { get async {
        if let custom = item as? APIWithCustomProperties {
            await custom.properties.compactMap({ TypeProperty_Wrap($0) })
        } else {
            []
        }
    }}
    
    public var customProperties_and_condition : Bool { get async {
        if let custom = item as? APIWithCustomProperties {
            await custom.andCondition
        } else {
            false
        }
    }}
    
    public var customParameters : [APICustomParameter_Wrap] { get async {
        if let custom = item as? CustomLogicAPI {
            await custom.parameters.compactMap({ APICustomParameter_Wrap($0) })
        } else {
            []
        }
    }}
    
    public var returnType : Sendable { get async {
        if let custom = item as? CustomLogicAPI {
            await custom.returnType
        } else {
            await item.entity.name
        }
    }}
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        
        let value: Sendable = switch propname {
        case "entity": await CodeObject_Wrap(item.entity)
        case "return-type" : try await CheckSendable(value: returnType, pInfo: pInfo)
        case "input-type" : await item.entity.name
        case "has-path" : await item.path.isNotEmpty
        case "path" : await item.path
        case "name" : await item.name
        case "type" : await item.type

        case "givenname" : await item.givenname
        case "base-url" : await item.baseUrl
        case "version" : await item.version
        case "query-params" : await queryParams
        
        case "is-create" : await item.type == .create
        case "is-update" : await item.type == .update
        case "is-delete" : await item.type == .delete
        case "is-get-by-id" : await item.type == .getById
        case "is-get-by-custom-props" : await item.type == .getByCustomProperties
        case "is-list" :  await item.type == .list
        case "is-list-by-custom-props" :  await item.type == .listByCustomProperties
        case "is-push-data" :  await item.type == .pushData
        case "is-push-datalist" :  await item.type == .pushDataList
        case "is-get-by-custom-logic" : await item.type == .getByUsingCustomLogic
        case "is-list-by-custom-logic" : await item.type == .listByUsingCustomLogic
        case "is-mutation-by-custom-logic" : await item.type == .mutationUsingCustomLogic
            
        case "properties-involved": await customProperties
        case "is-and-condition-for-properties-involved": await customProperties_and_condition
        case "custom-params" : await customParameters
            
        default:
            //nothing found; so check in module attributes
            try await resolveFallbackProperty(propname: propname, pInfo: pInfo)

        }
        
        return value
    }

    private func resolveFallbackProperty(propname: String, pInfo: ParsedInfo) async throws -> Sendable {
        let attribs = await item.attribs
        if await attribs.has(propname) {
            return await attribs[propname]
        } else {
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
    }
    
    public var debugDescription: String { get async {
        await item.debugDescription
    }}
    
    public init(_ item: API) {
        self.item = item
    }
}

public actor APIParam_Wrap : DynamicMemberLookup, Sendable {
    public let item: APIQueryParamWrapper
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Sendable? {

        let value: Sendable = switch propname {
            //case "query-param-obj" : item.queryParam
            case "prop-mapping-first" : item.propMaping.first
            case "param-name" : item.queryParam.name
            case "has-second-param-name" : item.queryParam.hasSecondParamName
            case "second-param-name" : item.queryParam.SecondName
            case "has-multiple-params" : item.queryParam.canHaveMultipleValues
            default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }

        return value
    }
    
    public init(_ item: APIQueryParamWrapper) {
        self.item = item
    }
}

public actor APICustomParameter_Wrap : DynamicMemberLookup, Sendable {
    public let item: MethodParameter
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Sendable? {
        
        let value: Sendable = switch propname {
        case "name" : item.name
        case "type" : item.type
        case "is-array" : item.type.isArray
        default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
        
        return value
    }
    
    public init(_ item: MethodParameter) {
        self.item = item
    }
}
