//
// SampleJson.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct SampleJson {
    private static let UNKNOWN = "--UnKnown--"
    private let entity: CodeObject
    private let typesModel: ParsedTypesCache
    
    public func string(openCloseBraces: Bool = false, openCloseQuotesInNames: Bool = true) -> String {
        return Self.toObjectString(entity, typesModel: self.typesModel, openCloseBraces: openCloseBraces, openCloseQuotesInNames: openCloseQuotesInNames)
    }
    
    static func toObjectString(_ object: CodeObject, typesModel: ParsedTypesCache, openCloseBraces:  Bool, openCloseQuotesInNames: Bool) -> String {
        var reqdProperties:[Property] = []
        
        for prop in object.properties {
            if prop.required == .yes && prop.type.kind != .id {
                reqdProperties.append(prop)
            }
        }
        
        return StringTemplate {
            if openCloseBraces {
                """
                {
                
                """
            } else {
                """


                """
            }
            
            for (index, prop) in reqdProperties.enumerated() {
                let includeComma = reqdProperties.count - 1 != index
                if openCloseQuotesInNames {
            """
                \"\(prop.name)\":
            """
                } else {
             """
                \(prop.name):
            """
                }
                Self.toPropString(prop, typesModel: typesModel, includeComma: includeComma, openCloseQuotesInNames: openCloseQuotesInNames)
                
                TabChar()
                EmptyLine()
            }
            
            if openCloseBraces {
                """
                    }
                """
            }
            
            //EmptyLine(2)
        }.string
    }
    
    static func toPropString(_ prop: Property, typesModel: ParsedTypesCache, includeComma: Bool, openCloseQuotesInNames: Bool) -> String {
        let prefix = prop.type.isArray ? " [" : ""
        var suffix = prop.type.isArray ? "]" : ""
        if includeComma {
            suffix = suffix + ","
        }
        
        let num = Int.random(in: 0..<100)
        let mocking = MockData_Generator()
        
        switch prop.type.kind {
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
            guard let entity = typesModel.get(for: typeName) else { return Self.UNKNOWN }
                if prop.type.isArray {
                    return prefix + Self.toObjectString(entity, typesModel: typesModel, openCloseBraces: true, openCloseQuotesInNames: openCloseQuotesInNames) + suffix
                } else {
                    return prefix + Self.toObjectString(entity, typesModel: typesModel, openCloseBraces: true, openCloseQuotesInNames: openCloseQuotesInNames)  + suffix
                }
            case .unKnown:
                return Self.UNKNOWN
        }
    }
    
    public init(entity: CodeObject, typesModel: ParsedTypesCache) {
        self.entity = entity
        self.typesModel = typesModel
    }
}
