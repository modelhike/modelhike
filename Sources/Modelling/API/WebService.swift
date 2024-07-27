//
// WebService_MonoRepo.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class WebService_MonoRepo : C4Container {
    var microServices: C4ComponentList { self.components }
    
    
    public init(name: String, microServices: C4ComponentList) {
        super.init(name: name, items: microServices)
    }
}
