//
//  CustomAPIs.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor CustomLogicAPI : API {
    public private(set) var api: GenericAPI
    public private(set) var state: APIState
    public private(set) var name: String = ""

    public let method: MethodObject
    
    public var parameters: [MethodParameter] { get async { await method.parameters }}
    public var returnType : TypeInfo { get async { await method.returnType }}

    public init(method: MethodObject, entity: CodeObject, version: Int = 1) async {
        self.method = method
        
        var type: APIType = .mutationUsingCustomLogic
        
        //If the return type is an object, assume it is either get-by or list api
        if await method.returnType.isObject() {
            if await method.returnType.isArray {
                type = .listByUsingCustomLogic
            } else {
                type = .getByUsingCustomLogic
            }
        }
        
        let methodName = await method.name.uppercasedFirst()
        api = await GenericAPI(entity: entity, name: methodName, type: type, version: version)
        state = await api.state
        name = await api.name
    }
}

public actor ListAPIByCustomProperties : APIWithCustomProperties {
    public private(set) var api: GenericAPI
    public private(set) var state: APIState
    public private(set) var name: String = ""
    
    public private(set) var andCondition : Bool = false
    public private(set) var properties: [Property] = []
    
    public func append(property: Property) async {
        self.properties.append(property)
        await updateName()
    }
    
    public func name(_ value: String) async {
        await self.state.name(value)
        self.name = value
    }
    
    public func andCondition(_ value: Bool) {
        self.andCondition = value
    }
    
    public init(entity: CodeObject, version: Int = 1) async {
        api = await GenericAPI(entity: entity, type: .listByCustomProperties, version: version)
        self.name = await api.name
        self.state = await api.state
    }
}

public actor GetAPIByCustomProperties : APIWithCustomProperties {
    public private(set) var api: GenericAPI
    public private(set) var state: APIState
    public private(set) var name: String = ""
    
    public var andCondition : Bool = false
    public private(set) var properties: [Property] = []
    
    public func append(_ property: Property) async {
        self.properties.append(property)
        await updateName()
    }
    
    public func name(_ value: String) async {
        await self.state.name(value)
        self.name = value
    }
    
    public init(entity: CodeObject, version: Int = 1) async {
        api = await GenericAPI(entity: entity, type: .getByCustomProperties, version: version)
        self.name = await api.name
        self.state = await api.state
    }
    
}

public protocol APIWithCustomProperties : API {
    var name: String {get}
    var api: GenericAPI{ get }
    var andCondition : Bool {get}
    var properties: [Property] {get}
    func name(_ value: String) async
}

public extension APIWithCustomProperties {
    func updateName() async {
        var propNames : [String] = []
        
        for property in self.properties {
            await propNames.append(property.name.uppercasedFirst())
        }
        
        let seperator = andCondition ? "And" : "Or"
        let joined = propNames.joined(separator: seperator)
        
        let newName = "list\(await entity.name.pluralized())By\(joined)"
        await self.name(newName)
    }
}
