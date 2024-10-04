//
// CodeObject_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class CodeObject_Wrap : ObjectWrapper {
    public private(set) var item: CodeObject
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }
    
    public lazy var properties : [TypeProperty_Wrap] = { item.properties.compactMap({ TypeProperty_Wrap($0) })
    }()
    
    public lazy var pushDataApis : [API_Wrap] = {
        self.item.getAPIs().compactMap({
            if ($0.type == .pushData ||
                $0.type == .pushDataList ) { return API_Wrap($0) } else {return nil}    })
    }()
    
    public subscript(member: String) -> Any {
        if member.hasPrefix("has-prop-") {
            let propName = member.removingPrefix("has-prop-")
            return item.hasProp(propName)
        }
        
        let value: Any = switch member {
            case "name": item.name
            case "given-name": item.givename
            case "properties" : properties
            case "entity" : item.dataType == .entity
            case "dto" : item.dataType == .dto
            case "common" : item.dataType == .valueType
            case "cache" : item.dataType == .cache
            case "workflow" : item.dataType == .workflow
            case "has-push-apis" : pushDataApis.count != 0
            
            default:
            //nothing found; so check in module attributes}
            item.attribs[member] as Any
        }
        
        return value
    }
    
    public var debugDescription: String { item.debugDescription }

    public init(_ item: CodeObject) {
        self.item = item
    }
}

public class TypeProperty_Wrap : ObjectWrapper {
    public private(set) var item: Property
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }
    
    public subscript(member: String) -> Any {
        if member.hasPrefix("has-attrib-") {
            let attributeName = member.removingPrefix("has-attrib-")
            return item.hasAttrib(attributeName)
        }
        
        if member.hasPrefix("attrib-") {
            let attributeName = member.removingPrefix("attrib-")
            return item.attribs[attributeName] as Any
        }
        
        let value: Any = switch member {
            case "name": 
            //if item.type == .id {
            //    "_id"
            //} else {
                item.name
            //}
            case "is-array" : item.isArray
            case "is-object" : item.isObject()
            case "is-number" : item.type == .int || item.type == .double
            case "is-bool", "is-boolean", "is-yesno" : item.type == .bool
            case "is-string" : item.type == .string
            case "is-id" : item.type == .id
            case "is-any" : item.type == .any
            case "is-date" : item.type == .date || item.type == .datetime
            case "is-buffer" : item.type == .buffer
            case "is-reference" :  item.isReference()
            case "is-extended-reference" : item.isExtendedReference()
            case "is-coded-value" : item.isCodedValue()
            case "is-custom-type" : item.isCustomType()
            case "custom-type" :
                if case let .customType(typeName) = item.type {
                    typeName
                } else { "" }
            case "obj-type" : item.objectTypeString()
            case "is-required": item.required == .yes
            default: 
            //nothing found; so check in module attributes}
            item.attribs[member] as Any
        }
        
        return value
    }
    
    public var debugDescription: String { item.debugDescription }

    public init(_ item: Property) {
        self.item = item
    }
}
