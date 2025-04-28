//
//  UIView.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor UIView : UIObject {
    public var givenname: String
    public var name: String
    public var members : [CodeMember] = []
    public var attachedSections = AttachedSections()
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []
    
    public let attribs = Attributes()
    public let tags = Tags()
    public let annotations = Annotations()
    
    public var methods : [MethodObject] { get async {
        await members.compactMap({
        if let method = $0 as? MethodObject { return method } else {return nil}
    }) }}
    
    public var dataType: ArtifactKind = .ui
    
    @discardableResult
    func append(_ item: CodeMember) -> Self {
        members.append(item)
        return self
    }
    
    public var debugDescription: String { get async {
        return "\(self.name) : \(self.members.count) items"
    }}
    
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

public protocol UIObject : ArtifactHolderWithAttachedSections, SendableDebugStringConvertible {
    var givenname: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get set}
    
    var methods : [MethodObject] { get async }
    func hasMethod(_ name: String) async -> Bool
    
    func isSameAs(_ obj: UIObject) async -> Bool
}

public extension UIObject {
    
    func hasMethod(_ name: String) async -> Bool {
        return await methods.contains(where: { await $0.name == name})
    }
    
    func isSameAs(_ obj: UIObject) async -> Bool {
        return await self.givenname == obj.givenname
    }
    
    @discardableResult
    func appendAttached(_ item: Artifact) -> Self {
        attached.append(item)
        return self
    }
}
