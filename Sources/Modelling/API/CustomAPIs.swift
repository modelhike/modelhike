//
// API`.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class CustomLogicAPI : API {
    public let method: MethodObject
    
    public var parameters: [MethodParameter] { method.parameters }
    public var returnType : PropertyKind? { method.returnType }

    public init(method: MethodObject, entity: CodeObject, version: Int = 1) {
        self.method = method
        super.init(entity: entity, type: .mutationUsingCustomLogic, version: version)
        
        self.name = method.name.uppercasedFirst()
    }
}

public class ListAPIByCustom : API, APIWithCustomProperties {
    public var andCondition : Bool = false
    public var properties: [Property] = [] {
        didSet { updateName() }
    }
    
    public init(entity: CodeObject, version: Int = 1) {
        super.init(entity: entity, type: .listByCustom, version: version)
    }
}

public class GetAPIByCustom : API, APIWithCustomProperties {
    public var andCondition : Bool = false
    public var properties: [Property] = [] {
        didSet { updateName() }
    }
    public init(entity: CodeObject, version: Int = 1) {
        super.init(entity: entity, type: .getByCustom, version: version)
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
