//
// API_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class API_Wrap : ObjectWrapper {
    public private(set) var item: API
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }
    
    public lazy var queryParams:  [APIParam_Wrap] = {
        item.queryParams.compactMap({ APIParam_Wrap($0) })
    }()
    
    public lazy var customProperties : [TypeProperty_Wrap] = {
        if let custom = item as? APIWithCustomProperties {
            custom.properties.compactMap({ TypeProperty_Wrap($0) })
        } else {
            []
        }
    }()
    
    public lazy var customProperties_and_condition : Bool = {
        if let custom = item as? APIWithCustomProperties {
            custom.andCondition
        } else {
            false
        }
    }()
    
    public lazy var customParameters : [APICustomParameter_Wrap] = {
        if let custom = item as? CustomLogicAPI {
            custom.parameters.compactMap({ APICustomParameter_Wrap($0) })
        } else {
            []
        }
    }()
    
    public lazy var returnType : Any = {
        if let custom = item as? CustomLogicAPI {
            custom.returnType as Any
        } else {
            item.entity.name
        }
    }()
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        
        let value: Any = switch propname {
            case "entity": CodeObject_Wrap(item.entity)
            case "return-type" : deepUnwrap(returnType) ?? ""
            case "input-type" : item.entity.name
            case "has-path" : item.path.isNotEmpty
            case "path" : item.path
            case "name" : item.name
            case "type" : item.type

            case "givenname" : item.givenname
            case "base-url" : item.baseUrl
            case "version" : item.version
            case "query-params" : queryParams
            
            case "is-create" : item.type == .create
            case "is-update" : item.type == .update
            case "is-delete" : item.type == .delete
            case "is-get-by-id" : item.type == .getById
            case "is-get-by-custom-props" : item.type == .getByCustomProperties
            case "is-list" :  item.type == .list
            case "is-list-by-custom-props" :  item.type == .listByCustomProperties
            case "is-push-data" :  item.type == .pushData
            case "is-push-datalist" :  item.type == .pushDataList
            case "is-get-by-custom-logic" : item.type == .getByUsingCustomLogic
            case "is-list-by-custom-logic" : item.type == .listByUsingCustomLogic
            case "is-mutation-by-custom-logic" : item.type == .mutationUsingCustomLogic
            
            case "properties-involved": customProperties
            case "is-and-condition-for-properties-involved": customProperties_and_condition
            case "custom-params" : customParameters
            
            default:
            //nothing found; so check in module attributes
            if item.attribs.has(propname) {
                item.attribs[propname] as Any
            } else {
                throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
            }
        }
        
        return value
    }

    public var debugDescription: String { item.debugDescription }
    
    public init(_ item: API) {
        self.item = item
    }
}

public class APIParam_Wrap : DynamicMemberLookup {
    public private(set) var item: APIQueryParamWrapper
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {

        let value: Any = switch propname {
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

public class APICustomParameter_Wrap : DynamicMemberLookup {
    public private(set) var item: MethodParameter
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        
        let value: Any = switch propname {
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
