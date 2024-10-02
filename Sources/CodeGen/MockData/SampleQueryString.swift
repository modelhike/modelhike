//
// SampleQueryString.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct SampleQueryString {
    private static let UNKNOWN = "--UnKnown--"
    private let api: API
    private let typesModel: ParsedTypesCache
    
    public var string: String {
        return Self.toQueryString(api, typesModel: self.typesModel)
    }
    
    static func toQueryString(_ api: API, typesModel: ParsedTypesCache) -> String {
        let reqdParams:[APIQueryParamWrapper] = api.queryParams
        
        return StringTemplate {
            
            for (index, param) in reqdParams.enumerated() {
                let includeSeparator = reqdParams.count - 1 != index

                if param.queryParam.hasSecondParamName {
                    "\(param.queryParam.name)="
                    Self.toPropString(param.propMaping, isEndValueInRange: false, api: api, typesModel: typesModel, includeSeparator: false)
                    
                    "&\(param.queryParam.SecondName)="

                    Self.toPropString(param.propMaping, isEndValueInRange: true, api: api, typesModel: typesModel, includeSeparator: includeSeparator)
                } else { // only single param
                    "\(param.queryParam.name)="
                    Self.toPropString(param.propMaping, isEndValueInRange: true, api: api, typesModel: typesModel, includeSeparator: includeSeparator)
                }
            }
        }.string
    }
    
    static func toPropString(_ mapping: QueryParam_PropertyNameMapping, isEndValueInRange: Bool, api: API, typesModel: ParsedTypesCache, includeSeparator: Bool) -> String {
        let propName = mapping.first
        
        guard let prop = typesModel.getLastPropInRecursive(propName, inObj: api.entity.name) else { return "" }
        
        var suffix = ""
        if includeSeparator {
            suffix = suffix + "&"
        }
        
        var num = Int.random(in: 0..<50)
        if isEndValueInRange {
            num = Int.random(in: 51..<100)
        }
        
        let mocking = MockData_Generator()
        
        switch prop.type {
            case .int, .double, .float :
                return  "\(num)" + suffix
            case .bool: return "true" + suffix
            case .string: return "\(prop.name)" + suffix
            case .id: return  mocking.randomObjectId_MongoDb() + suffix
            case .any: return  mocking.randomObjectId_MongoDb() + suffix
            case .date, .datetime: 
                if isEndValueInRange {
                    return "\"\(Date.now.ISO8601Format())\"" + suffix
                } else {
                    return "\"\(Date.now.removing(days: 7).ISO8601Format())\"" + suffix
                }
            case .buffer:
                return Self.UNKNOWN
            case .reference(_), .multiReference(_):
                return Self.UNKNOWN
            case .extendedReference(_), .multiExtendedReference(_):
                return Self.UNKNOWN
            case .codedValue(_):
                return Self.UNKNOWN
            case .customType(_):
                return Self.UNKNOWN
            case .unKnown:
                return Self.UNKNOWN
        }
    }
    
    public init(api: API, typesModel: ParsedTypesCache) {
        self.api = api
        self.typesModel = typesModel
    }
}
