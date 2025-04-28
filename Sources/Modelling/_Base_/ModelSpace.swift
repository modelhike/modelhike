//
//  ModelSpace.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ModelSpace: SendableDebugStringConvertible {
    public var name: String = ""
    
    public let containers = C4ContainerList()
    public let modules = C4ComponentList()
    
    public func append(container item: C4Container) async {
        await containers.append(item)
    }
    
    public func append(module item: C4Component) async {
        await modules.append(item)
    }
    
    public var debugDescription: String { get async {
        return """
        model space: \(self.name)
        container: \(await self.containers.count) containers
        modules:\(await self.modules.count) modules
        """
    }}
    
    internal init(){
        self.name = ""
    }
}
