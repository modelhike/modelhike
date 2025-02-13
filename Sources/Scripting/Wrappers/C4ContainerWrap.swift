//
// C4Container_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4Container_Wrap : ObjectWrapper {
    public private(set) var item: C4Container
    var appModel : AppModel
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }

    public lazy var types : [CodeObject_Wrap] = { item.types.compactMap({ CodeObject_Wrap($0)})
    }()
    
    public lazy var apis : [API_Wrap] = { item.types.flatMap({
        $0.getAPIs().compactMap({ API_Wrap($0) })
    }) }()
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        let value: Any = switch propname {
            case "name": item.name
            case "modules" : item.components(item.components, appModel: appModel)
            case "commons" : item.components(appModel.commonModel, appModel: appModel)
            case "default-module" : item.getFirstModule(appModel: appModel) as Any
            
            case "types" : types
            case "has-any-apis" : apis.count != 0
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

    public init(_ item: C4Container, model: AppModel ) {
        self.item = item
        self.appModel = model
    }
}

