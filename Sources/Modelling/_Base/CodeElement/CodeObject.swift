//
// CodeObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol CodeObject : ArtifactContainerWithAttachedSections, CustomDebugStringConvertible {
    var dataType: ArtifactKind {get set}
    var properties : [Property] {get}
        
    var methods : [MethodObject] {get}
    func hasMethod(_ name: String) -> Bool

    func hasProp(_ name: String, isCaseSensitive: Bool) -> Bool
    func getProp(_ name: String, isCaseSensitive: Bool) -> Property?
    func getLastPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property?
    func getArrayPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property?
    
    func isSameAs(_ CodeObject: CodeObject) -> Bool
    
    var attached : [Artifact] {get set}
    var mixins : [CodeObject] {get set}

}

typealias CodeObjectBuilder = ResultBuilder<CodeObject>


public extension CodeObject {
    
    func hasProp(_ name: String, isCaseSensitive: Bool = false) -> Bool {
        if isCaseSensitive {
            return properties.contains(where: { $0.name == name || $0.givenname == name})
        } else {
            return properties.contains(where: { $0.name.lowercased() == name.lowercased() ||
                                                $0.givenname.lowercased() == name.lowercased()})
        }
    }
    
    func hasMethod(_ name: String) -> Bool {
        return methods.contains(where: { $0.name == name || $0.givenname == name })
    }
    
    func getProp(_ name: String, isCaseSensitive: Bool = false) -> Property? {
        if isCaseSensitive {
            return properties.first(where: { $0.name == name || $0.givenname == name})
        } else {
            return properties.first(where: { $0.name.lowercased() == name.lowercased() ||
                                            $0.givenname.lowercased() == name.lowercased()})
        }
    }
    
    func getLastPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = getProp(propName) else { return nil }
            if !prop.type.isObject() { return prop }
            //dump(appmodel)
            guard let entity = appModel.get(for: prop.type.objectString()) else { return nil }
            let remainingName =  String(name.suffix(from: name.index(after: index)))
            return entity.getLastPropInRecursive(remainingName, appModel: appModel)
            
        } else { // not recursive
            return getProp(name)
        }
        
    }
    
    func getArrayPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = getProp(propName) else { return nil }
            if !prop.type.isObject() { return nil }
            
            if prop.type.isArray {
                return prop
            }
            
            guard let entity = appModel.get(for: prop.type.objectString()) else { return nil }
            let remainingName =  String(name.suffix(from: name.index(after: index)))
            return entity.getArrayPropInRecursive(remainingName, appModel: appModel)
            
        } else { // not recursive
            if let prop = getProp(name) {
                if prop.type.isArray {
                    return prop
                }
            }
            return nil
        }
        
    }
    
    func isSameAs(_ CodeObject: CodeObject) ->  Bool {
        return self.givenname == CodeObject.givenname
    }
    
    @discardableResult
    func appendAttached(_ item: Artifact) -> Self {
        attached.append(item)
        return self
    }
}
