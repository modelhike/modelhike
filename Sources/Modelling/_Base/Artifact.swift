//
// Artifact.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Artifact : HasAttributes, HasAnnotations, HasTags {
    var givenname: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get}
}

public protocol ArtifactHolder : Artifact {

}

public protocol ArtifactHolderWithAttachedSections : ArtifactHolder, HasAttachedSections {

}

typealias ArtifactHolderBuilder = ResultBuilder<ArtifactHolder>


public enum ArtifactKind {
    case unKnown, entity, embeddedType, valueType, dto, api, apiInput, cache, workflow, event, agent, data, ui, uxFlow, container, attachedSection, custom
}
