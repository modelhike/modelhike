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
    
    private func params() -> [APIParam_Wrap] {
        item.queryParams.compactMap({ APIParam_Wrap($0) })
    }
    
    public subscript(member: String) -> Any {
        
        let value: Any = switch member {
            case "entity": CodeObject_Wrap(item.entity)
            case "has-path" : item.path.isNotEmpty
            case "path" : item.path
            case "base-url" : item.baseUrl
            case "version" : item.version
            case "query-params" : params()
            case "is-create" : item.type == .create
            case "is-update" : item.type == .update
            case "is-delete" : item.type == .delete
            case "is-get-by-id" : item.type == .getById
            case "is-list" :  item.type == .list
            default:
            //nothing found; so check in module attributes}
            item.attribs[member] as Any
        }
        
        return value
    }

    public init(_ item: API) {
        self.item = item
    }
}

public class APIParam_Wrap : DynamicMemberLookup {
    public private(set) var item: APIQueryParamWrapper
    
    public subscript(member: String) -> Any {

        let value: Any = switch member {
            //case "query-param-obj" : item.queryParam
            case "prop-mapping-first" : item.propMaping.first
            case "param-name" : item.queryParam.name
            case "has-second-param-name" : item.queryParam.hasSecondParamName
            case "second-param-name" : item.queryParam.SecondName
            case "has-multiple-params" : item.queryParam.canHaveMultipleValues
            default: ""
        }

        return value
    }
    
    public init(_ item: APIQueryParamWrapper) {
        self.item = item
    }
}
