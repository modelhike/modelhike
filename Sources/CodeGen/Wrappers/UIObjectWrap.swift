//
// UIObject_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class UIObject_Wrap : ObjectWrapper {
    public private(set) var item: UIObject
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }
    
    public func dynamicLookup(property propname: String, lineNo: Int) throws -> Any {
        
        let value: Any = switch propname {
        case "name": item.name
        case "given-name": item.givename
        default:
            //nothing found; so check in module attributes
            if item.attribs.has(propname) {
                item.attribs[propname] as Any
            } else {
                throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(lineNo, propname)
            }
        }
        
        return value
    }
    
    public var debugDescription: String { item.debugDescription }

    public init(_ item: UIObject) {
        self.item = item
    }
}
