//
// ObjectAttributeManager.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ObjectAttributeManager {
    let ctx: Context
    
    public func getObjAttributeValue(objName: String, attributeName: String) -> Optional<Any> {
        
        if let obj = ctx.variables[objName] as? HasAttributes {
            if obj.attribs.has(attributeName) {
                return obj.attribs[attributeName]
            }
        }
        
        if let dynamicLookup = ctx.variables[objName] as? DynamicMemberLookup {
            return dynamicLookup[attributeName]
        }
        
        return nil
    }
    
    public func setObjAttribute(objName: String, attributeName: String, valueExpression: String, modifiers: [ModifierInstance], lineNo: Int, with ctx: Context) throws {
        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = try ctx.evaluate(expression: valueExpression, lineNo: lineNo) {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, lineNo: lineNo, with: ctx) {
                    obj.attribs[attributeName] = modifiedBody
                } else {
                    obj.attribs.removeValue(forKey: attributeName)
                }
            } else {
                obj.attribs.removeValue(forKey: attributeName)
            }
        }
    }
    
    public func setObjAttribute(objName: String, attributeName: String, body: String?, modifiers: [ModifierInstance], lineNo: Int, with ctx: Context) throws {
        if let obj = ctx.variables[objName] as? HasAttributes {
            if let body = body {
                if let modifiedBody = try Modifiers.apply(to: body, modifiers: modifiers, lineNo: lineNo, with: ctx) {
                    obj.attribs[attributeName] = modifiedBody
                } else {
                    obj.attribs.removeValue(forKey: attributeName)
                }
            } else {
                obj.attribs.removeValue(forKey: attributeName)
            }
        }
    }
    
    public init(context ctx: Context) {
        self.ctx = ctx
    }
}
