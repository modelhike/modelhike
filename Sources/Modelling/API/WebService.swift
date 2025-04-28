//
//  WebService_MonoRepo.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor WebService_MonoRepo {
    let container: C4Container
    var microServices: C4ComponentList { get async { await container.components }}
    
    public init(name: String, microServices: C4ComponentList) {
        self.container = .init(name: name, items: microServices)
    }
}
