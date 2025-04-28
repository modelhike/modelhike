//
//  C4Container_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Container_Wrap : ObjectWrapper {
    public let item: C4Container
    var appModel : AppModel
    
    public var attribs: Attributes { item.attribs }

    public var types : [CodeObject_Wrap] { get async {
        await item.types.compactMap({ CodeObject_Wrap($0)})
    }}
    
    public var apis : [API_Wrap] { get async {
        await item.types.flatMap({
            await $0.getAPIs().snapshot().compactMap({ API_Wrap($0) })
        })
    }}
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        let value: Sendable = switch propname {
        case "name": await item.name
        case "modules" : await item.components(item.components, appModel: appModel)
        case "commons" : await item.components(appModel.commonModel, appModel: appModel)
        case "default-module" : await item.getFirstModule(appModel: appModel)
            
        case "types" : await types
        case "has-any-apis" : await apis.count != 0
           default:
            //nothing found; so check in module attributes
            try await resolveFallbackProperty(propname: propname, pInfo: pInfo)
        }
        
        return value
    }
    
    private func resolveFallbackProperty(propname: String, pInfo: ParsedInfo) async throws -> Sendable {
        let attribs = item.attribs
        if await attribs.has(propname) {
            return await attribs[propname]
        } else {
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
    }
    
    public var debugDescription: String { get async { await item.debugDescription }}

    public init(_ item: C4Container, model: AppModel ) {
        self.item = item
        self.appModel = model
    }
}

