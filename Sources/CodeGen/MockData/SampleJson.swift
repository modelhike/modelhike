//
//  SampleJson.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct SampleJson {
    private static let UNKNOWN = "--UnKnown--"
    private let entity: CodeObject
    private let typesModel: ParsedTypesCache
    
    public func string(openCloseBraces: Bool = false, openCloseQuotesInNames: Bool = true) async -> String {
        return await Self.toObjectString(entity, typesModel: self.typesModel, openCloseBraces: openCloseBraces, openCloseQuotesInNames: openCloseQuotesInNames)
    }
    
    static func toObjectString(_ object: CodeObject, typesModel: ParsedTypesCache, openCloseBraces:  Bool, openCloseQuotesInNames: Bool) async -> String {
        var reqdProperties:[Property] = []
        
        for prop in await object.properties {
            let kind = await prop.type.kind
            if await prop.required == .yes && kind != .id {
                reqdProperties.append(prop)
            }
        }
        
        return await StringTemplate {
            if openCloseBraces {
                """
                {
                
                """
            } else {
                """


                """
            }
            
            for (index, prop) in reqdProperties.enumerated() {
                let propname = await prop.name

                let includeComma = reqdProperties.count - 1 != index
                if openCloseQuotesInNames {
            """
                \"\(propname)\":
            """
                } else {
             """
                \(propname):
            """
                }
                await Self.toPropString(prop, typesModel: typesModel, includeComma: includeComma, openCloseQuotesInNames: openCloseQuotesInNames)
                
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
    
    static func toPropString(_ prop: Property, typesModel: ParsedTypesCache, includeComma: Bool, openCloseQuotesInNames: Bool) async -> String {
        let prefix = await prop.type.isArray ? " [" : ""
        var suffix = await prop.type.isArray ? "]" : ""
        if includeComma {
            suffix = suffix + ","
        }
        
        let num = Int.random(in: 0..<100)
        let mocking = MockData_Generator()
        
        switch await prop.type.kind {
        case .int, .double, .float :
            return prefix + " \(num)" + suffix
        case .bool: return prefix + " true" + suffix
        case .string: return prefix + " \"\(await prop.name) \(num)\"" + suffix
        case .id: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
        case .any: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
        case .date, .datetime: return prefix + " \"\(Date.now.ISO8601Format())\"" + suffix
        case .buffer: return prefix + " Buffer" + suffix
        case .reference(_), .multiReference(_):
            return prefix +
            """
             {
                    "ref": "\(mocking.randomObjectId_MongoDb())",
                    "display": "\(await prop.name) \(num)"
                }
            """
            + suffix
        case .extendedReference(_), .multiExtendedReference(_):
            return prefix +
            """
             {
                    "ref": "\(mocking.randomObjectId_MongoDb())",
                    "display": "\(await prop.name) \(num)"
                }
            """
            + suffix
        case .codedValue(_):
            return prefix +
            """
             {
                    "vsRef": "\(mocking.randomObjectId_MongoDb())",
                    "display": "\(await prop.name) \(num)",
                    "code": "BE\(num)"
                }
            """
            + suffix
        case let .customType(typeName):
            guard let entity = await typesModel.get(for: typeName) else { return Self.UNKNOWN }
            if await prop.type.isArray {
                return await prefix + Self.toObjectString(entity, typesModel: typesModel, openCloseBraces: true, openCloseQuotesInNames: openCloseQuotesInNames) + suffix
            } else {
                return await prefix + Self.toObjectString(entity, typesModel: typesModel, openCloseBraces: true, openCloseQuotesInNames: openCloseQuotesInNames)  + suffix
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
