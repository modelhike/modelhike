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
    
    public lazy var apis : [API_Wrap] = {
        self.item.getAPIs().compactMap({ return API_Wrap($0)})
    }()
    
    public lazy var pushDataApis : [API_Wrap] = {
        self.item.getAPIs().compactMap({
            if ($0.type == .pushData ||
                $0.type == .pushDataList ) { return API_Wrap($0) } else {return nil}    })
    }()
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        if propname.hasPrefix("has-prop-") {
            let propName = propname.removingPrefix("has-prop-")
            return item.hasProp(propName)
        }
        
        let value: Any = switch propname {
        case "name": item.name
        case "given-name": item.givenname
        case "properties" :
            if properties.count > 0 {
                properties
            } else {
                let msg = "properties empty for \(item.name)"
                throw TemplateSoup_ParsingError.invalidExpression_CustomMessage(msg, pInfo)
            }
            
        case "entity" : item.dataType == .entity
        case "dto" : item.dataType == .dto
        case "common" : item.dataType == .valueType
        case "cache" : item.dataType == .cache
        case "workflow" : item.dataType == .workflow
        case "has-push-apis" : pushDataApis.count != 0
        case "has-any-apis" : apis.count != 0
        default:
            //nothing found; so check in module attributes
            if item.attribs.has(propname) {
                item.attribs[propname] as Any
            } else if let value = RuntimeReflection.getValueOf(property: propname, in: item, with: pInfo) {
                //chk for the object property using reflection
                value
            } else {
                throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
            }
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
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        if propname.hasPrefix("has-attrib-") {
            let attributeName = propname.removingPrefix("has-attrib-")
            return item.hasAttrib(attributeName)
        }
        
        if propname.hasPrefix("attrib-") {
            let attributeName = propname.removingPrefix("attrib-")
            return item.attribs[attributeName] as Any
        }
        
        let value: Any = switch propname {
            case "name": 
            //if item.type == .id {
            //    "_id"
            //} else {
                item.name
            //}
            case "is-array" : item.type.isArray
            case "is-object" : item.type.isObject()
            case "is-number" : item.type == .int || item.type == .double
            case "is-bool", "is-boolean", "is-yesno" : item.type == .bool
            case "is-string" : item.type == .string
            case "is-id" : item.type == .id
            case "is-any" : item.type == .any
            case "is-date" : item.type == .date || item.type == .datetime
            case "is-buffer" : item.type == .buffer
            case "is-reference" :  item.type.isReference()
            case "is-extended-reference" : item.type.isExtendedReference()
            case "is-coded-value" : item.type.isCodedValue()
            case "is-custom-type" : item.type.isCustomType
            case "custom-type" :
            if case let .customType(typeName) = item.type.kind {
                    typeName
                } else { "" }
            case "obj-type" : item.type.objectString()
            case "is-required": item.required == .yes
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

    public init(_ item: Property) {
        self.item = item
    }
}
