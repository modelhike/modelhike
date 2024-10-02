//
// UIView_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class UIView_Wrap : ObjectWrapper {
    public private(set) var item: UIObject
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }
    
    public subscript(member: String) -> Any {
        
        let value: Any = switch member {
        case "name": item.name
        case "given-name": item.givename
        default:
            //nothing found; so check in module attributes}
            item.attribs[member] as Any
        }
        
        return value
    }
    
    public init(_ item: UIObject) {
        self.item = item
    }
}
