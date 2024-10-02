//
// Artifact.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Artifact : HasAttributes, HasAnnotations, HasTags {
    var givename: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get}
}

public protocol ArtifactContainer : Artifact {

}

typealias ArtifactContainerBuilder = ResultBuilder<ArtifactContainer>


public enum ArtifactKind {
    case unKnown, entity, embeddedType, valueType, dto, api, apiInput, cache, workflow, event, agent, data, ui, uxFlow, container, custom
}
