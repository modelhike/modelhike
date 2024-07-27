//
// CodeObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol CodeObject : ArtifactContainer, CustomDebugStringConvertible {
    var givename: String {get}
    var name: String {get}
    var dataType: CodeElementKind {get set}
    var properties : [Property] {get}
    
    var methods : [Method] {get}
    func hasMethod(_ name: String) -> Bool

    func hasProp(_ name: String) -> Bool
    func getProp(_ name: String) -> Property?
    func getLastPropInRecursive(_ name: String, appModel: ParsedModelCache) -> Property?
    func getArrayPropInRecursive(_ name: String, appModel: ParsedModelCache) -> Property?
    
    func isSameAs(_ CodeObject: CodeObject) -> Bool
}

public enum CodeElementKind {
    case unKnown, entity, embeddedType, valueType, dto, cache, workflow, event, agent, data, ui, uxFlow, custom
}

typealias CodeObjectBuilder = ResultBuilder<CodeObject>
