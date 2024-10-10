//
// DtoObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class UIView : UIObject {
    public var givenname: String
    public var name: String
    public var members : [CodeMember] = []
    public var attachedSections = AttachedSections()
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []
    
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public lazy var methods : [MethodObject] = { members.compactMap({
        if let method = $0 as? MethodObject { return method } else {return nil}
    }) }()
    
    public var dataType: ArtifactKind = .ui
    
    @discardableResult
    func append(_ item: CodeMember) -> Self {
        members.append(item)
        return self
    }
    
    public var debugDescription: String {
        return "\(self.name) : \(self.members.count) items"
    }
    
    public init(name: String, @CodeMemberBuilder _ builder: () -> [CodeMember]) {
        self.givenname = name
        self.name = name.normalizeForVariableName()
        self.members = builder()
    }
    
    public init(name: String) {
        self.givenname = name
        self.name = name.normalizeForVariableName()
    }
}

public protocol UIObject : ArtifactContainerWithAttachedSections, CustomDebugStringConvertible {
    var givenname: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get set}
    
    var methods : [MethodObject] {get}
    func hasMethod(_ name: String) -> Bool
    
    func isSameAs(_ obj: UIObject) -> Bool
}

public extension UIObject {
    
    func hasMethod(_ name: String) -> Bool {
        return methods.contains(where: { $0.name == name})
    }
    
    func isSameAs(_ obj: UIObject) ->  Bool {
        return self.givenname == obj.givenname
    }
    
    @discardableResult
    func appendAttached(_ item: Artifact) -> Self {
        attached.append(item)
        return self
    }
}
