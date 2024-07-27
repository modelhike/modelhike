//
// Artifact.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Artifact : HasAttributes, HasAnnotations, HasTags {
    
}

public protocol ArtifactContainer : Artifact {

}

typealias ArtifactContainerBuilder = ResultBuilder<ArtifactContainer>
