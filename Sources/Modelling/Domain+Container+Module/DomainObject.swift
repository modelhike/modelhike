//
// DomainObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class DomainObject : CodeObject {
    public var givename: String
    public var name: String
    public var parentName: String?
    public var items : [CodeMember] = []
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public lazy var properties : [Property] = { items.compactMap({
        if let prop = $0 as? Property { return prop } else {return nil}
    }) }()
    
    public lazy var methods : [Method] = { items.compactMap({
        if let method = $0 as? Method { return method } else {return nil}
    }) }()
    
    public var dataType: CodeElementKind = .unKnown

    @discardableResult
    func append(_ item: CodeMember) -> Self {
        items.append(item)
        return self
    }
    
    public var debugDescription: String {
        return "\(self.name) : \(self.items.count) items"
    }
    
    public init(_ name: String, @CodeMemberBuilder _ builder: () -> [CodeMember]) {
        self.givename = name
        self.name = name.normalizeForVariableName()
        self.items = builder()
    }
    
    public init(_ name: String, parent: String, @CodeMemberBuilder _ builder: () -> [CodeMember]) {
        self.givename = name
        self.name = name.normalizeForVariableName()
        self.parentName = parent.normalizeForVariableName()
        self.items = builder()
    }
    
    public init(_ name: String) {
        self.givename = name
        self.name = name.normalizeForVariableName()
    }
    
    public init(_ name: String, parent: String) {
        self.givename = name
        self.name = name.normalizeForVariableName()
        self.parentName = parent.normalizeForVariableName()
    }
}


public extension CodeObject {
    
    func hasProp(_ name: String) -> Bool {
        return properties.contains(where: { $0.name == name})
    }
    
    func hasMethod(_ name: String) -> Bool {
        return methods.contains(where: { $0.name == name})
    }
    
    func getProp(_ name: String) -> Property? {
        return properties.first(where: { $0.name == name})
    }
    
    func getLastPropInRecursive(_ name: String, appModel: ParsedModelCache) -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = properties.first(where: { $0.name == propName}) else { return nil }
            if !prop.isObject() { return prop }
            //dump(appmodel)
            guard let entity = appModel.get(for: prop.getObjectString()) else { return nil }
            let remainingName =  String(name.suffix(from: name.index(after: index)))
            return entity.getLastPropInRecursive(remainingName, appModel: appModel)

        } else { // not recursive
            return getProp(name)
        }
        
    }
    
    func getArrayPropInRecursive(_ name: String, appModel: ParsedModelCache) -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = properties.first(where: { $0.name == propName}) else { return nil }
            if !prop.isObject() { return nil }
            
            if prop.isArray {
                return prop
            }
            
            guard let entity = appModel.get(for: prop.getObjectString()) else { return nil }
            let remainingName =  String(name.suffix(from: name.index(after: index)))
            return entity.getArrayPropInRecursive(remainingName, appModel: appModel)

        } else { // not recursive
            if let prop = getProp(name) {
                if prop.isArray {
                    return prop
                }
            }
            return nil
        }
        
    }
    
    func isSameAs(_ CodeObject: CodeObject) ->  Bool {
        return self.givename == CodeObject.givename
    }
}
