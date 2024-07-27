//
// AppModel.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class AppModel {
    var parsedModel = ParsedModelCache()
    private var commons = C4ComponentList()
    public var containers = C4ContainerList()
    
    public var commonModel : C4ComponentList {
        get { return commons }
        set {
            commons = newValue
            commons.addTo(model: parsedModel)
        }
    }
    
    public func container(named name: String) -> C4Container? {
        return containers.first(where: {$0.name == name})
    }
    
    public func append(_ item: C4Container) {
        containers.append(item)
        item.components.addTo(model: parsedModel)
    }
    
    public func append(contentsOf items: C4ContainerList) {
        for item in items.containers {
            append(item)
        }
    }
    
    public init() {
        
    }

}
