//
//  API.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor API : Artifact {
    public let attribs = Attributes()
    public let tags = Tags()
    public let annotations = Annotations()

    public let name: String
    public let givenname: String
    public let dataType: ArtifactKind = .api

    public let entity : CodeObject
    public let type: APIType
    
    public var path: String
    public var baseUrl: String
    public var version: Int
    public private(set) var queryParams: [APIQueryParamWrapper] = []
    
    public func get(_ key: String) -> String? {
        return queryParams.first(where: {$0.queryParam.name == key})?.propMaping.givenString
    }
    
    public func set(_ key: String, value newValue: String) {
        let wrapped = APIQueryParamWrapper(queryParam: QueryParam_KeyMapping(key), propMaping: QueryParam_PropertyNameMapping(newValue), entity: entity)
        queryParams.append(wrapped)
    }
    
    public var debugDescription: String { get async {
        var str =  """
                    \(self.name)
                    """
        str += .newLine
        
        return str
    }}
    
    public init(entity item: CodeObject, type: APIType, version: Int = 1) async {
        let entityname = await item.name
        self.entity = item
        self.type = type
        self.baseUrl = entityname.slugify()
        self.version = version
        
        switch type {
        case .getById:
            self.path = ":id"
            self.name = "get\(entityname)ById"
        case .delete:
            self.path = ":id"
            self.name = "delete\(entityname)"
        case .list:
            self.path = ""
            let plural = entityname.pluralized()
            self.name = "list\(plural)"
        case .associate: //will be create for the association
            self.path = ""
            self.name = "associate\(entityname)"
        case .deassosiate: //will be delete for the association
            self.path = ""
            self.name = "deassosiate\(entityname)"
        case .activate:
            self.path = "activate"
            self.name = "activate\(entityname)"
        case .deactivate:
            self.path = "deactivate"
            self.name = "deactivate\(entityname)"
        case .create:
            self.path = ""
            self.name = "add\(entityname)"
        case .update:
            self.path = ""
            self.name = "update\(entityname)"
        case .getByCustomProperties:
            self.path = ""
            self.name = "get\(entityname)ByCustomProps"
        case .listByCustomProperties:
            self.path = ""
            let plural = entityname.pluralized()
            self.name = "list\(plural)ByCustomProps"
        case .getByUsingCustomLogic:
            self.path = ""
            self.name = "get\(entityname)ByCustomLogic"
        case .listByUsingCustomLogic:
            self.path = ""
            self.name = "list\(entityname)ByCustomLogic"
        case .mutationUsingCustomLogic:
            self.path = ""
            self.name = "mutation\(entityname)ByCustomLogic"
        case .pushData:
            self.path = ""
            let plural = entityname.pluralized()
            self.name = "\(plural)Subscription"
        case .pushDataList:
            self.path = ""
            let plural = entityname.pluralized()
            self.name = "\(plural)Subscription"
        }
        
        self.givenname = self.name
    }
}

public enum APIType: Sendable {
    case create, update, delete,
         getById, getByCustomProperties, 
         mutationUsingCustomLogic, getByUsingCustomLogic, listByUsingCustomLogic,
         list, listByCustomProperties,
         pushData, pushDataList,
         associate, deassosiate, activate, deactivate
}

public enum QueryParamKind: Sendable {
    case unKnown, int, string, date
}

actor QueryParamStore {
    private var storage: [String: String] = [:]

    func set(_ key: String, value: String) {
        storage[key] = value
    }

    func get(_ key: String) -> String? {
        return storage[key]
    }
}

public actor APIQueryParamStore {
    private var params: [APIQueryParamWrapper]

    init() {
        self.params = []
    }
    
    init(params: [APIQueryParamWrapper]) {
        self.params = params
    }

    public func getParams() -> [APIQueryParamWrapper] {
        return params
    }

    public func append(_ param: APIQueryParamWrapper) {
        params.append(param)
    }
}

public struct APIQueryParamWrapper: Sendable {
    public var queryParam: QueryParam_KeyMapping
    public var propMaping : QueryParam_PropertyNameMapping
    public var entity: CodeObject
    
    public init(queryParam: QueryParam_KeyMapping, propMaping: QueryParam_PropertyNameMapping, entity: CodeObject) {
        self.queryParam = queryParam
        self.propMaping = propMaping
        self.entity = entity
    }
}

public struct QueryParam_KeyMapping : Hashable, Sendable {
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

public struct QueryParam_PropertyNameMapping: Sendable {
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
    func getAPIs() async -> APIList {
        let attached = self.attached
        let apis = APIList()
        
        for item in attached {
            if let api = item as? API {
                await apis.append(api)
            }
        }
        return apis
    }
    
    @discardableResult
    func appendAPI(_ type : APIType) async -> API {
        let api = await API(entity: self, type: type)
        attached.append(api)
        
        if type == .list {
            if let getAllAnnotation = await self.annotations[AnnotationConstants.listApi] {
                if let mapping = getAllAnnotation as? MappingAnnotation {
                    for item in mapping.mappings {
                        await api.set(item.key, value: item.value)
                    }
                }
            }
        }
        return api
    }
    
    func hasNoAPIs() async -> Bool {
        let apis = await getAPIs()
        
        return await apis.count == 0
    }
}
