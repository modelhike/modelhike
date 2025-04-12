//
//  ModelSpace.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ModelSpace {
    public var name: String = ""
    
    public internal(set) var containers = C4ContainerList()
    public internal(set) var modules = C4ComponentList()
    
    public func append(container item: C4Container) {
        containers.append(item)
    }
    
    public func append(module item: C4Component) {
        modules.append(item)
    }
    
    public var debugDescription: String {
        return """
        model space: \(self.name)
        container: \(self.containers.count) containers
        modules:\(self.modules.count) modules
        """
    }
    
    internal init(){
        self.name = ""
    }
}
