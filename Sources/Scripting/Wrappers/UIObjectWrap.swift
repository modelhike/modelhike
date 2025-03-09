//
//  UIObject_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class UIObject_Wrap: ObjectWrapper {
    public private(set) var item: UIObject

    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }

    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {

        let value: Any =
            switch propname {
            case "name": item.name
            case "given-name": item.givenname
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

    public init(_ item: UIObject) {
        self.item = item
    }
}
