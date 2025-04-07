//
//  Artifact.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Artifact_NonActor : HasAttributes, HasAnnotations, HasTags, CustomDebugStringConvertible, Sendable {
    var givenname: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get}
}

public protocol Artifact : HasAttributes_Actor, HasAnnotations_Actor, HasTags_Actor, SendableDebugStringConvertible, Actor {
    var givenname: String {get}
    var name: String {get}
    var dataType: ArtifactKind {get}
}

public protocol ArtifactHolder : Artifact {

}

public protocol ArtifactHolder_NonActor : Artifact_NonActor {
    
}


public protocol ArtifactHolderWithAttachedSections : ArtifactHolder, HasAttachedSections {

}

typealias ArtifactHolderBuilder = ResultBuilder<ArtifactHolder>


public enum ArtifactKind: Sendable {
    case unKnown, entity, embeddedType, valueType, dto, api, apiInput, cache, workflow, event, agent, data, ui, uxFlow, container, attachedSection, custom
}
