//
//  CustomAPIs.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class CustomLogicAPI : API {
    public let method: MethodObject
    
    public var parameters: [MethodParameter] { method.parameters }
    public var returnType : TypeInfo { method.returnType }

    public init(method: MethodObject, entity: CodeObject, version: Int = 1) {
        self.method = method
        
        var type: APIType = .mutationUsingCustomLogic
        
        //If the return type is an object, assume it is either get-by or list api
        if method.returnType.isObject() {
            if method.returnType.isArray {
                type = .listByUsingCustomLogic
            } else {
                type = .getByUsingCustomLogic
            }
        }
        
        super.init(entity: entity, type: type, version: version)
        self.name = method.name.uppercasedFirst()
    }
}

public class ListAPIByCustomProperties : API, APIWithCustomProperties {
    public var andCondition : Bool = false
    public var properties: [Property] = [] {
        didSet { updateName() }
    }
    
    public init(entity: CodeObject, version: Int = 1) {
        super.init(entity: entity, type: .listByCustomProperties, version: version)
    }
}

public class GetAPIByCustomProperties : API, APIWithCustomProperties {
    public var andCondition : Bool = false
    public var properties: [Property] = [] {
        didSet { updateName() }
    }
    public init(entity: CodeObject, version: Int = 1) {
        super.init(entity: entity, type: .getByCustomProperties, version: version)
    }
}

public protocol APIWithCustomProperties : AnyObject {
    var name: String {get set}
    var entity: CodeObject {get}
    var andCondition : Bool {get}
    var properties: [Property] {get}
    func updateName()
}

public extension APIWithCustomProperties {
    func updateName() {
        var propNames : [String] = []
        
        for property in self.properties {
            propNames.append(property.name.uppercasedFirst())
        }
        
        let seperator = andCondition ? "And" : "Or"
        let joined = propNames.joined(separator: seperator)
        
        self.name = "list\(entity.name.pluralized())By\(joined)"
    }
}
