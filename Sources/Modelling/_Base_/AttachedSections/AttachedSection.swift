//
//  AttachedSection.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor AttachedSection : ArtifactHolder {
   
    public var debugDescription: String {
        return "AttachedSection(\(name))"
    }
    
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations:  Annotations {
        get async { await containingObject.annotations }
    }

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .attachedSection
    internal var containingObject: ArtifactHolderWithAttachedSections
    
    public internal(set) var items : [Artifact]

    public func appendAttached(_ item: Artifact) {
        self.items.append(item)
    }
    
    public init(code: String, for obj: ArtifactHolderWithAttachedSections) {
        self.name = code
        self.givenname = code
        self.items = []
        self.containingObject = obj
    }
}
