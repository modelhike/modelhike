//
// ObjectAttributeManager.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ObjectAttributeManager {
    
    public func getObjAttributeValue(objName: String, propName: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        let ctx = pInfo.ctx

        if let _ = propName.firstIndex(of: ".") { //hierarchial prop name
            if let dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup {
                return try dynamicLookup.getValueOf(property: propName, with: pInfo)
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
        }
        
        return nil
    }
    
    public func setObjAttribute(objName: String, propName: String, valueExpression: String, modifiers: [ModifierInstance], with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        var hasDot = false
        
        if let _ = propName.firstIndex(of: ".") { //hierarchial prop name
            hasDot = true
        }
        
        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
           dynamicLookup.hasSettable(property: propName) {
            
            if let body = try ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
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
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
                    obj.attribs[propName] = modifiedBody
                    return
                }
            }
            
            obj.attribs.removeValue(forKey: propName)
            return
        }
        
        throw TemplateSoup_ParsingError.invalidStmt(pInfo)

    }
    
    public func setObjAttribute(objName: String, propName: String, value: Any?, with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        
        var hasDot = false
        
        if let _ = propName.firstIndex(of: ".") { //hierarchial prop name
            hasDot = true
        }
        
        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
           dynamicLookup.hasSettable(property: propName) {
            
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
    
    public func setObjAttribute(objName: String, propName: String, body: String?, modifiers: [ModifierInstance], with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        var hasDot = false
        
        if let _ = propName.firstIndex(of: ".") { //hierarchial prop name
            hasDot = true
        }
        
        if var dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup,
           dynamicLookup.hasSettable(property: propName) {
            
            if let body = body {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
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
            if let body = body {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
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
