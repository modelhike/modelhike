//
// C4Component_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4Component_Wrap : ObjectWrapper {
    public private(set) var item: C4Component
    var model : AppModel
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }

    public lazy var types : [CodeObject_Wrap] = { item.types.compactMap({ CodeObject_Wrap($0)})
    }()
    
    public lazy var embeddedTypes : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .embeddedType {CodeObject_Wrap($0)} else {nil}})
    }()
    
    public lazy var entities : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .entity {CodeObject_Wrap($0)} else {nil}})
    }()
    
    public lazy var inputObjects : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .apiInput {CodeObject_Wrap($0)} else {nil}})
    }()
    
    public lazy var apis : [API_Wrap] = { item.items.compactMap({
        if let e = $0 as? API { return API_Wrap(e) } else {return nil}
    }) }()
    
    public subscript(member: String) -> Any {
        let value: Any = switch member {
            case "name": item.name
            case "types" : types
            case "embeddedTypes" : embeddedTypes
            case "entities" : entities
            case "inputObjects" : inputObjects
            default:
            //nothing found; so check in module attributes}
            item.attribs[member] as Any
        }
        
        return value
    }
    
    public init(_ item: C4Component, model: AppModel ) {
        self.item = item
        self.model = model
    }
}





