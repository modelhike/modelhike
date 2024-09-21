//
// SampleJson.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct SampleJson {
    private static let UNKNOWN = "--UnKnown--"
    private let entity: CodeObject
    private let appModel: ParsedModelCache
    
    public var string: String {
        return Self.toObjectString(entity, appModel: self.appModel, openClose: false)
    }
    
    static func toObjectString(_ object: CodeObject, appModel: ParsedModelCache, openClose:  Bool) -> String {
        var reqdProperties:[Property] = []
        
        for prop in object.properties {
            if prop.required == .yes && prop.type != .id {
                reqdProperties.append(prop)
            }
        }
        
        return StringTemplate {
            if openClose {
                """
                {
                
                """
            } else {
                """


                """
            }
            
            for (index, prop) in reqdProperties.enumerated() {
                let includeComma = reqdProperties.count - 1 != index
            """
                \"\(prop.name)\":
            """
                Self.toPropString(prop, appModel: appModel, includeComma: includeComma)
                
                TabChar()
                EmptyLine()
            }
            
            if openClose {
                """
                    }
                """
            }
            
            //EmptyLine(2)
        }.string
    }
    
    static func toPropString(_ prop: Property, appModel: ParsedModelCache, includeComma: Bool) -> String {
        let prefix = prop.isArray ? " [" : ""
        var suffix = prop.isArray ? "]" : ""
        if includeComma {
            suffix = suffix + ","
        }
        
        let num = Int.random(in: 0..<100)
        let mocking = MockData_Generator()
        
        switch prop.type {
            case .int, .double, .float :
                return prefix + " \(num)" + suffix
            case .bool: return prefix + " true" + suffix
            case .string: return prefix + " \"\(prop.name) \(num)\"" + suffix
            case .id: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
            case .any: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
            case .date, .datetime: return prefix + " \"\(Date.now.ISO8601Format())\"" + suffix
            case .buffer: return prefix + " Buffer" + suffix
            case .reference(_), .multiReference(_):
                return prefix +
                """
                 {
                        "ref": "\(mocking.randomObjectId_MongoDb())",
                        "display": "\(prop.name) \(num)"
                    }
                """
                + suffix
            case .extendedReference(_), .multiExtendedReference(_):
                return prefix +
                """
                 {
                        "ref": "\(mocking.randomObjectId_MongoDb())",
                        "display": "\(prop.name) \(num)"
                    }
                """
                + suffix
            case .codedValue(_):
                return prefix +
                """
                 {
                        "vsRef": "\(mocking.randomObjectId_MongoDb())",
                        "display": "\(prop.name) \(num)",
                        "code": "BE\(num)"
                    }
                """
                + suffix
            case let .customType(typeName):
            guard let entity = appModel.get(for: typeName) else { return Self.UNKNOWN }
                if prop.isArray {
                    return prefix + Self.toObjectString(entity, appModel: appModel, openClose: true) + suffix
                } else {
                    return prefix + Self.toObjectString(entity, appModel: appModel, openClose: true)  + suffix
                }
            case .unKnown:
                return Self.UNKNOWN
        }
    }
    
    public init(entity: CodeObject, appModel: ParsedModelCache) {
        self.entity = entity
        self.appModel = appModel
    }
}
