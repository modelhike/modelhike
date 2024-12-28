//
// ObjectAttributeManager.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ObjectAttributeManager {
    
    public func getObjAttributeValue(objName: String, attributeName: String, with pInfo: ParsedInfo) throws -> Optional<Any> {
        let ctx = pInfo.ctx

        if let obj = ctx.variables[objName] as? HasAttributes {
            if obj.attribs.has(attributeName) {
                return obj.attribs[attributeName]
            }
        }
        
        if let dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup {
            return try dynamicLookup.dynamicLookup(property: attributeName, pInfo: pInfo)
        }
        
        return nil
    }
    
    public func setObjAttribute(objName: String, attributeName: String, valueExpression: String, modifiers: [ModifierInstance], with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        
        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = try ctx.evaluate(expression: valueExpression, with: pInfo) {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
                    obj.attribs[attributeName] = modifiedBody
                } else {
                    obj.attribs.removeValue(forKey: attributeName)
                }
            } else {
                obj.attribs.removeValue(forKey: attributeName)
            }
        }
    }
    
    public func setObjAttribute(objName: String, attributeName: String, value: Any?, with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        
        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = value {
                obj.attribs[attributeName] = body
            } else {
                obj.attribs.removeValue(forKey: attributeName)
            }
        }
    }
    
    public func setObjAttribute(objName: String, attributeName: String, body: String?, modifiers: [ModifierInstance], with pInfo: ParsedInfo) throws {
        
        let ctx = pInfo.ctx
        
        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = body {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, pInfo: pInfo) {
                    obj.attribs[attributeName] = modifiedBody
                } else {
                    obj.attribs.removeValue(forKey: attributeName)
                }
            } else {
                obj.attribs.removeValue(forKey: attributeName)
            }
        }
    }
    
    public init() {
    }
}
