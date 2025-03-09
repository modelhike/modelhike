//
//  AttachedSection.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class AttachedSection : ArtifactHolder {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .attachedSection

    public internal(set) var items : [Artifact]

    public func appendAttached(_ item: Artifact) {
        self.items.append(item)
    }
    
    public init(code: String) {
        self.name = code
        self.givenname = code
        self.items = []
    }
}
