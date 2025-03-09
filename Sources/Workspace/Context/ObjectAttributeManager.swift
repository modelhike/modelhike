//
//  ObjectAttributeManager.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ObjectAttributeManager {

    public func getObjAttributeValue(objName: String, propName: String, with pInfo: ParsedInfo)
        throws -> Any?
    {
        let ctx = pInfo.ctx

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            if let dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup {
                return try getDynamicLookupValue(
                    lookup: dynamicLookup, propName: propName, with: pInfo)
            } else {
                throw TemplateSoup_ParsingError.invalidExpression(objName, pInfo)
            }
        } else {
            //attributes cannot be hierarchial
            if let obj = ctx.variables[objName] as? HasAttributes {
                if obj.attribs.has(propName) {
                    return obj.attribs[propName]
                }
            }

            if let dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup {
                return try dynamicLookup.getValueOf(property: propName, with: pInfo)
            }

            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(
                objName, pInfo)
        }
    }

    private func getDynamicLookupValue(
        lookup: DynamicMemberLookup, propName: String, with pInfo: ParsedInfo
    ) throws -> Any? {

        if let dotIndex = propName.firstIndex(of: ".") {  //hierarchial prop name
            let beforeDot = String(propName[..<dotIndex])
            let afterDot = String(propName[propName.index(after: dotIndex)...])

            let value = try lookup.getValueOf(property: beforeDot, with: pInfo)

            //if the returned value is a dynamic lookup
            if let dynamicLookup = value as? DynamicMemberLookup {
                return try getDynamicLookupValue(
                    lookup: dynamicLookup, propName: afterDot, with: pInfo)
            } else {
                return value
            }
        } else {
            return try lookup.getValueOf(property: propName, with: pInfo)
        }
    }

    public func setObjAttribute(
        objName: String, propName: String, valueExpression: String, modifiers: [ModifierInstance],
        with pInfo: ParsedInfo
    ) throws {

        let ctx = pInfo.ctx
        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
            dynamicLookup.hasSettable(property: propName)
        {

            if let body = try ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, with: pInfo) {
                    try dynamicLookup.setValueOf(property: propName, value: modifiedBody, with: pInfo)
                    return
                }
            }

            try dynamicLookup.setValueOf(property: propName, value: nil, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = try ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    obj.attribs[propName] = modifiedBody
                    return
                }
            }

            obj.attribs.removeValue(forKey: propName)
            return
        }

        throw TemplateSoup_ParsingError.invalidStmt(pInfo)

    }

    public func setObjAttribute(
        objName: String, propName: String, value: Any?, with pInfo: ParsedInfo
    ) throws {

        let ctx = pInfo.ctx

        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
            dynamicLookup.hasSettable(property: propName)
        {

            try dynamicLookup.setValueOf(property: propName, value: value, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = value {
                obj.attribs[propName] = body
            } else {
                obj.attribs.removeValue(forKey: propName)
            }
            return
        }

        throw TemplateSoup_ParsingError.invalidStmt(pInfo)
    }

    public func setObjAttribute(
        objName: String, propName: String, body: String?, modifiers: [ModifierInstance],
        with pInfo: ParsedInfo
    ) throws {

        let ctx = pInfo.ctx
        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
            dynamicLookup.hasSettable(property: propName)
        {

            if let body = body {
                if let modifiedBody = try Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    try dynamicLookup.setValueOf(
                        property: propName, value: modifiedBody, with: pInfo)
                    return
                }
            }

            try dynamicLookup.setValueOf(property: propName, value: nil, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = body {
                if let modifiedBody = try Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    obj.attribs[propName] = modifiedBody
                    return
                }
            }

            obj.attribs.removeValue(forKey: propName)
            return
        }

        throw TemplateSoup_ParsingError.invalidStmt(pInfo)
    }

    public init() {
    }
}
