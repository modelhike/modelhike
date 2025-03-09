//
//  WebService_MonoRepo.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class WebService_MonoRepo : C4Container {
    var microServices: C4ComponentList { self.components }
    
    
    public init(name: String, microServices: C4ComponentList) {
        super.init(name: name, items: microServices)
    }
}
