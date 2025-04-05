//
//  CodeObject.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol CodeObject: ArtifactHolderWithAttachedSections, SendableDebugStringConvertible {
    var dataType: ArtifactKind { get set }
    var properties: [Property] { get }

    var methods: [MethodObject] { get }
    func hasMethod(_ name: String) -> Bool

    func hasProp(_ name: String, isCaseSensitive: Bool) -> Bool
    func getProp(_ name: String, isCaseSensitive: Bool) -> Property?
    func getLastPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property?
    func getArrayPropInRecursive(_ name: String, appModel: ParsedTypesCache) -> Property?

    func isSameAs(_ CodeObject: CodeObject) -> Bool

    var attached: [Artifact] { get set }
    var mixins: [CodeObject] { get set }
    func append(mixin: CodeObject)
}

typealias CodeObjectBuilder = ResultBuilder<CodeObject>

extension CodeObject {
    public func append(mixin: CodeObject) {
        mixins.append(mixin)
    }
    
    public func hasProp(_ name: String, isCaseSensitive: Bool = false) async -> Bool {
        if let _ = await getProp(name, isCaseSensitive: isCaseSensitive) {
            return true
        } else {
            return false
        }
    }

    public func hasMethod(_ name: String, isCaseSensitive: Bool = false) async -> Bool {
        if let _ = await getMethod(name, isCaseSensitive: isCaseSensitive) {
            return true
        } else {
            return false
        }
    }

    public func getMethod(_ name: String, isCaseSensitive: Bool = false) async -> MethodObject? {
        for item in methods {
            let item_givenname = await isCaseSensitive ? item.givenname : item.givenname.lowercased()
            let item_name = await isCaseSensitive ? item.name : item.name.lowercased()
            
            let nameToCompare = isCaseSensitive ? name : name.lowercased()
            
            if item_givenname == nameToCompare ||
                item_name == nameToCompare {
                return item
            }
        }
        
        return nil
    }
    
    public func getProp(_ name: String, isCaseSensitive: Bool = false) async -> Property? {
        for item in properties {
            let item_givenname = await isCaseSensitive ? item.givenname : item.givenname.lowercased()
            let item_name = await isCaseSensitive ? item.name : item.name.lowercased()
            
            let nameToCompare = isCaseSensitive ? name : name.lowercased()
            
            if item_givenname == nameToCompare ||
                item_name == nameToCompare {
                return item
            }
        }
        
        return nil
    }

    public func getLastPropInRecursive(_ name: String, appModel: ParsedTypesCache) async -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = await getProp(propName) else { return nil }
            if !prop.type.isObject() { return prop }
            //dump(appmodel)
            guard let entity = await appModel.get(for: prop.type.objectString()) else { return nil }
            let remainingName = String(name.suffix(from: name.index(after: index)))
            return await entity.getLastPropInRecursive(remainingName, appModel: appModel)

        } else {  // not recursive
            return await getProp(name)
        }

    }

    public func getArrayPropInRecursive(_ name: String, appModel: ParsedTypesCache) async -> Property? {
        if let index = name.firstIndex(of: ".") {
            let propName = String(name.prefix(upTo: index))
            guard let prop = await getProp(propName) else { return nil }
            if !prop.type.isObject() { return nil }

            if prop.type.isArray {
                return prop
            }

            guard let entity = await appModel.get(for: prop.type.objectString()) else { return nil }
            let remainingName = String(name.suffix(from: name.index(after: index)))
            return await entity.getArrayPropInRecursive(remainingName, appModel: appModel)

        } else {  // not recursive
            if let prop = await getProp(name) {
                if prop.type.isArray {
                    return prop
                }
            }
            return nil
        }

    }

    public func isSameAs(_ codeObject: CodeObject) async -> Bool {
        return await self.givenname == codeObject.givenname
    }

    @discardableResult
    public func appendAttached(_ item: Artifact) -> Self {
        attached.append(item)
        return self
    }
}
