//
// API`.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class API : Artifact {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givename: String = ""
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
    
    public init(entity: CodeObject, type: APIType, version: Int = 1) {
        self.entity = entity
        self.type = type
        self.baseUrl = entity.name.slugify()
        self.version = version
        
        switch type {
        case .getById:
            self.path = ":id"
        case .delete:
            self.path = ":id"
        case .list:
            self.path = ""
        case .associate: //will be create for the association
            self.path = ""
        case .deassosiate: //will be delete for the association
            self.path = ""
        case .activate:
            self.path = "activate"
        case .deactivate:
            self.path = "deactivate"
        default:
            self.path = ""
        }
    }
}

public enum APIType {
    case create, update, delete, getById, list,
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
        let apis = APIList()
        
        for item in attached {
            if let api = item as? API {
                apis.append(api)
            }
        }
        
        return apis.count == 0
    }
}
