//
//  ObjectAttributeManager.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ObjectAttributeManager {

    public func getObjAttributeValue(objName: String, propName: String, with pInfo: ParsedInfo)
    async throws -> Sendable?
    {
        let ctx = pInfo.ctx
        let obj = await ctx.variables[objName]
        
        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            if let dynamicLookup = obj as? DynamicMemberLookup {
                return try await getDynamicLookupValue(
                    lookup: dynamicLookup, propName: propName, with: pInfo)
            } else {
                throw TemplateSoup_ParsingError.invalidExpression(objName, pInfo)
            }
        } else { //attributes cannot be hierarchial
            
            //MARK: Check diff attributes in different types of objects
            //Revisit this repitition, in future, if needed
            if let obj = obj as? HasAttributes {
                if await obj.attribs.has(propName) {
                    return await obj.attribs[propName]
                }
            }

            if let obj = obj as? HasAttributes_Actor {
                if await obj.attribs.has(propName) {
                    return await obj.attribs[propName]
                }
            }
            
            if let obj = obj as? HasAsyncAttributes {
                if await obj.attribs.has(propName) {
                    return await obj.attribs[propName]
                }
            }
            
            //MARK: Continue with others
            if let dynamicLookup = obj as? DynamicMemberLookup {
                return try await dynamicLookup.getValueOf(property: propName, with: pInfo)
            }

            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(
                objName, pInfo)
        }
    }

    private func getDynamicLookupValue(
        lookup: DynamicMemberLookup, propName: String, with pInfo: ParsedInfo
    ) async throws -> Sendable? {

        if let dotIndex = propName.firstIndex(of: ".") {  //hierarchial prop name
            let beforeDot = String(propName[..<dotIndex])
            let afterDot = String(propName[propName.index(after: dotIndex)...])

            let value = try await lookup.getValueOf(property: beforeDot, with: pInfo)

            //if the returned value is a dynamic lookup
            if let dynamicLookup = value as? DynamicMemberLookup {
                return try await getDynamicLookupValue(
                    lookup: dynamicLookup, propName: afterDot, with: pInfo)
            } else {
                return value
            }
        } else {
            return try await lookup.getValueOf(property: propName, with: pInfo)
        }
    }

    public func setObjAttribute(
        objName: String, propName: String, valueExpression: String, modifiers: [ModifierInstance],
        with pInfo: ParsedInfo
    ) async throws {

        let ctx = pInfo.ctx
        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        if let dynamicLookup = await ctx.variables[objName] as? DynamicMemberLookup,
           await dynamicLookup.hasSettable(property: propName)
        {

            if let body = try await ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try await Modifiers.apply(to: body, modifiers: modifiers, with: pInfo) {
                    try await dynamicLookup.setValueOf(property: propName, value: modifiedBody, with: pInfo)
                    return
                }
            }

            try await dynamicLookup.setValueOf(property: propName, value: nil, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        //MARK: Check diff attributes in different types of objects
        //Revisit this repitition, in future, if needed
        if let obj = await ctx.variables[objName] as? HasAttributes {
            if let body = try await ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }
        
        if let obj = await ctx.variables[objName] as? HasAttributes_Actor {
            if let body = try await ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }
        
        if let obj = await ctx.variables[objName] as? HasAsyncAttributes {
            if let body = try await ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }
        
        //MARK:  continue with others
        
        throw TemplateSoup_ParsingError.invalidStmt(pInfo)

    }

    public func setObjAttribute(
        objName: String, propName: String, value: Sendable?, with pInfo: ParsedInfo
    ) async throws {

        let ctx = pInfo.ctx

        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        let obj = await ctx.variables[objName]
        
        if let dynamicLookup = obj as? DynamicMemberLookup,
           await dynamicLookup.hasSettable(property: propName)
        {

            try await dynamicLookup.setValueOf(property: propName, value: value, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        //MARK: Check diff attributes in different types of objects
        //Revisit this repitition, in future, if needed
        if let obj = obj as? HasAttributes {
            if let body = value {
                await obj.attribs.set(propName, value: body)
            } else {
                await obj.attribs.removeValue(forKey: propName)
            }
            return
        }

        if let obj = obj as? HasAttributes_Actor {
            if let body = value {
                await obj.attribs.set(propName, value: body)
            } else {
                await obj.attribs.removeValue(forKey: propName)
            }
            return
        }
        
        if let obj = obj as? HasAsyncAttributes {
            if let body = value {
                await obj.attribs.set(propName, value: body)
            } else {
                await obj.attribs.removeValue(forKey: propName)
            }
            return
        }
        
        //MARK:  continue with others
        
        throw TemplateSoup_ParsingError.invalidStmt(pInfo)
    }

    public func setObjAttribute(
        objName: String, propName: String, body: String?, modifiers: [ModifierInstance],
        with pInfo: ParsedInfo
    ) async throws {

        let ctx = pInfo.ctx
        var hasDot = false

        if propName.firstIndex(of: ".") != nil {  //hierarchial prop name
            hasDot = true
        }

        if let dynamicLookup = await ctx.variables[objName] as? DynamicMemberLookup,
           await dynamicLookup.hasSettable(property: propName)
        {

            if let body = body {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    try await dynamicLookup.setValueOf(
                        property: propName, value: modifiedBody, with: pInfo)
                    return
                }
            }

            try await dynamicLookup.setValueOf(property: propName, value: nil, with: pInfo)
            return
        }

        if hasDot {
            //attributes cannot have hierarchy
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }

        //MARK: Check diff attributes in different types of objects
        //Revisit this repitition, in future, if needed
        if let obj = await ctx.variables[objName] as? HasAttributes {
            if let body = body {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }

        if let obj = await ctx.variables[objName] as? HasAttributes_Actor {
            if let body = body {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }
        
        if let obj = await ctx.variables[objName] as? HasAsyncAttributes {
            if let body = body {
                if let modifiedBody = try await Modifiers.apply(
                    to: body, modifiers: modifiers, with: pInfo)
                {
                    await obj.attribs.set(propName, value: modifiedBody)
                    return
                }
            }

            await obj.attribs.removeValue(forKey: propName)
            return
        }
        
        //MARK:  continue with others
        
        throw TemplateSoup_ParsingError.invalidStmt(pInfo)
    }

    public init() {
    }
}
