//
// C4System.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4System : ArtifactContainer {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givename: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var containers = C4ContainerList()
    
    public func append(_ item: C4Container) {
        containers.append(item)
    }
    
    public var count: Int { containers.count }
    
    public func removeAll() {
        containers.removeAll()
    }
    
    public var debugDescription: String {
        var str =  """
                    \(self.name)
                    containers \(self.containers.count):
                    """
        str += .newLine
        
        for item in containers {
            str += item.givename + .newLine
            
        }
        
        return str
    }
    
    public init(name: String, items: C4Container...) {
        self.name = name
        self.givename = name
        self.containers.append(contentsOf: items)
    }
    
    public init(name: String, items: [C4Container]) {
        self.name = name
        self.givename = name
        self.containers.append(contentsOf: items)
    }
    
    public init(name: String, items: C4ContainerList) {
        self.name = name
        self.givename = name
        self.containers = items
    }
    
    internal init(){
        self.name = ""
    }
}
