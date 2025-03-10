//
//  API.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class API : Artifact, CustomDebugStringConvertible {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .api

    public let entity : CodeObject
    public let type: APIType
    
    public var path: String
    public var baseUrl: String
    public var version: Int
    public private(set) var queryParams: [APIQueryParamWrapper] = []
    
    public subscript(key: String) -> String? {
        get {
            return queryParams.first(where: {$0.queryParam.name == key})?.propMaping.givenString
        }
        set {
            let wrapped = APIQueryParamWrapper(queryParam: QueryParam_KeyMapping(key), propMaping: QueryParam_PropertyNameMapping(newValue), entity: entity)
            queryParams.append(wrapped)
        }
    }
    
    public var debugDescription: String {
        var str =  """
                    \(self.name)
                    """
        str += .newLine
        
        return str
    }
    
    public init(entity: CodeObject, type: APIType, version: Int = 1) {
        self.entity = entity
        self.type = type
        self.baseUrl = entity.name.slugify()
        self.version = version
        
        switch type {
        case .getById:
            self.path = ":id"
            self.name = "get\(entity.name)ById"
        case .delete:
            self.path = ":id"
            self.name = "delete\(entity.name)"
        case .list:
            self.path = ""
            let plural = entity.name.pluralized()
            self.name = "list\(plural)"
        case .associate: //will be create for the association
            self.path = ""
            self.name = "associate\(entity.name)"
        case .deassosiate: //will be delete for the association
            self.path = ""
            self.name = "deassosiate\(entity.name)"
        case .activate:
            self.path = "activate"
            self.name = "activate\(entity.name)"
        case .deactivate:
            self.path = "deactivate"
            self.name = "deactivate\(entity.name)"
        case .create:
            self.path = ""
            self.name = "add\(entity.name)"
        case .update:
            self.path = ""
            self.name = "update\(entity.name)"
        case .getByCustomProperties:
            self.path = ""
            self.name = "get\(entity.name)ByCustomProps"
        case .listByCustomProperties:
            self.path = ""
            let plural = entity.name.pluralized()
            self.name = "list\(plural)ByCustomProps"
        case .getByUsingCustomLogic:
            self.path = ""
            self.name = "get\(entity.name)ByCustomLogic"
        case .listByUsingCustomLogic:
            self.path = ""
            self.name = "list\(entity.name)ByCustomLogic"
        case .mutationUsingCustomLogic:
            self.path = ""
            self.name = "mutation\(entity.name)ByCustomLogic"
        case .pushData:
            self.path = ""
            let plural = entity.name.pluralized()
            self.name = "\(plural)Subscription"
        case .pushDataList:
            self.path = ""
            let plural = entity.name.pluralized()
            self.name = "\(plural)Subscription"
        }
        
        self.givenname = self.name
    }
}

public enum APIType {
    case create, update, delete, 
         getById, getByCustomProperties, 
         mutationUsingCustomLogic, getByUsingCustomLogic, listByUsingCustomLogic,
         list, listByCustomProperties,
         pushData, pushDataList,
         associate, deassosiate, activate, deactivate
}

public enum QueryParamKind {
    case unKnown, int, string, date
}

public struct APIQueryParamWrapper {
    public var queryParam: QueryParam_KeyMapping
    public var propMaping : QueryParam_PropertyNameMapping
    public var entity: CodeObject
    
    public init(queryParam: QueryParam_KeyMapping, propMaping: QueryParam_PropertyNameMapping, entity: CodeObject) {
        self.queryParam = queryParam
        self.propMaping = propMaping
        self.entity = entity
    }
}

public struct QueryParam_KeyMapping : Hashable {
    public var name: String
    public var SecondName: String
    public var canHaveMultipleValues: Bool = false
    
    public init(_ name: String) {
        let split = name.split(separator: ",")

        if split.count > 1 {
            self.name = String(split[0]).trim()
            self.SecondName = String(split[1]).trim()
        } else {
            self.name = name.trim()
            self.SecondName = ""
        }
        
        if self.name.hasSuffix("...") {
            self.name = String(self.name.dropLast(3))
            self.canHaveMultipleValues = true
        }
    }
    
    public var hasSecondParamName : Bool {
        return self.SecondName.isNotEmpty
    }
    
    public init(_ name: String, SecondName: String? = nil) {
        self.name = name.trim()
        self.SecondName = SecondName?.trim() ?? ""
        
        if self.name.hasSuffix("...") {
            self.name = String(self.name.dropLast(3))
            self.canHaveMultipleValues = true
        }
    }
}

public struct QueryParam_PropertyNameMapping {
    public private(set) var givenString: String
    public var split: [String]
    
    public var first: String {
        return String(split.first!)
    }
    
    public var last: String {
        return String(split.last!)
    }
    
    public var hasMultipleMappings: Bool {
        return split.count > 1
    }
    
    public var properties: [String] {
        return split
    }
    
    public init(_ givenString: String?) {
        self.givenString = givenString ?? ""
        self.split = self.givenString.split(separator: ",").trim()
    }
    
}

public extension CodeObject {
    func getAPIs() -> APIList {
        let apis = APIList()
        
        for item in attached {
            if let api = item as? API {
                apis.append(api)
            }
        }
        return apis
    }
    
    @discardableResult
    func appendAPI(_ type : APIType) -> API {
        let api = API(entity: self, type: type)
        attached.append(api)
        
        if type == .list {
            if let getAllAnnotation = self.annotations[AnnotationConstants.listApi] {
                if let mapping = getAllAnnotation as? MappingAnnotation {
                    for item in mapping.mappings {
                        api[item.key] = item.value
                    }
                }
            }
        }
        return api
    }
    
    func hasNoAPIs() -> Bool {
        let apis = getAPIs()
        
        return apis.count == 0
    }
}
