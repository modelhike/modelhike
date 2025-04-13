//
// CodeObject_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor CodeObject_Wrap: ObjectWrapper {
    public let item: CodeObject

    public var attribs: Attributes { get async { await item.attribs }}

    public var properties: [TypeProperty_Wrap] { get async {
        await item.properties.compactMap({ TypeProperty_Wrap($0) })
    }}

    public var apis: [API_Wrap] { get async {
        await self.item.getAPIs().snapshot().compactMap({ return API_Wrap($0) })
    }}

    public var pushDataApis: [API_Wrap] { get async {
        await self.item.getAPIs().snapshot().compactMap({
            if $0.type == .pushData || $0.type == .pushDataList {
                return API_Wrap($0)
            } else {
                return nil
            }
        })
    }}

    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        if propname.hasPrefix("has-prop-") {
            let propName = propname.removingPrefix("has-prop-")
            return await item.hasProp(propName)
        }

        let value: Sendable =
            switch propname {
            case "name": await item.name
            case "given-name": await item.givenname
            case "properties":
                if await properties.count > 0 {
                    await properties
                } else {
                    let msg = "properties empty for \(await item.name)"
                    throw TemplateSoup_ParsingError.invalidExpression_CustomMessage(msg, pInfo)
                }

            case "entity": await item.dataType == .entity
            case "dto": await item.dataType == .dto
            case "common": await item.dataType == .valueType
            case "cache": await item.dataType == .cache
            case "workflow": await item.dataType == .workflow
            case "has-push-apis": await pushDataApis.count != 0
            case "has-any-apis": await apis.count != 0
            default:
                //nothing found; so check in module attributes
                try await resolveFallbackProperty(propname: propname, pInfo: pInfo)
            }

        return value
    }

    private func resolveFallbackProperty(propname: String, pInfo: ParsedInfo) async throws -> Sendable? {
        let attribs = await item.attribs
        if await attribs.has(propname) {
            return await attribs[propname]
        } else if let value = RuntimeReflection.getValueOf(
            property: propname, in: item, with: pInfo)
        {
            //chk for the object property using reflection
            //handle whether it is Sendable here itself
            return try CheckSendable(propname, value: value, pInfo: pInfo)
        } else {
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
    }
    
    public var debugDescription: String { get async { await item.debugDescription }}

    public init(_ item: CodeObject) {
        self.item = item
    }
}

public actor TypeProperty_Wrap: ObjectWrapper {
    public let item: Property

    public var attribs: Attributes { item.attribs }

    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        if propname.hasPrefix("has-attrib-") {
            let attributeName = propname.removingPrefix("has-attrib-")
            return await item.hasAttrib(attributeName)
        }

        if propname.hasPrefix("attrib-") {
            let attributeName = propname.removingPrefix("attrib-")
            return await item.attribs[attributeName]
        }

        let value: Sendable =
            switch propname {
            case "name":
                //if item.type == .id {
                //    "_id"
                //} else {
                await item.name
            //}
            case "is-array": await item.type.isArray
            case "is-object": await item.type.isObject()
            case "is-number": await item.type.isNumeric
            case "is-bool", "is-boolean", "is-yesno": await item.type == .bool
            case "is-string": await item.type == .string
            case "is-id": await item.type == .id
            case "is-any": await item.type == .any
            case "is-date": await item.type.isDate
            case "is-buffer": await item.type == .buffer
            case "is-reference": await item.type.isReference()
            case "is-extended-reference": await item.type.isExtendedReference()
            case "is-coded-value": await item.type.isCodedValue()
            case "is-custom-type": await item.type.isCustomType
            case "custom-type":
                if case let .customType(typeName) = await item.type.kind {
                    typeName
                } else {
                    ""
                }
            case "obj-type": await item.type.objectString()
            case "is-required": await item.required == .yes
            default:
                //nothing found; so check in module attributes
                try await resolveFallbackProperty(propname: propname, pInfo: pInfo)
            }

        return value
    }

    private func resolveFallbackProperty(propname: String, pInfo: ParsedInfo) async throws -> Sendable {
        if await item.attribs.has(propname) {
            return await item.attribs[propname]
        } else {
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
    }
    
    public var debugDescription: String { get async { await item.debugDescription }}

    public init(_ item: Property) {
        self.item = item
    }
}
