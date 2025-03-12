//
//  PassDownAndProcessAnnotationsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public struct PassDownAndProcessAnnotationsPass  : LoadingPass {
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        
        //pass the annotations of the component to its child items
        ws.model.containers.forEach { container in
            
            for type in container.types {
                type.annotations.append(contentsOf: container.annotations)
            }
            
        }
        
        //process annotation for types
        try ws.model.containers.forEach { container in
            
            for type in container.types {
                
                for annotation in type.annotations.annotationsList {
                    try AnnotationProcessor.process(annotation, for: type)
                }
                
                //after processing, if the type has not apis,
                //if it is not marked with "@no-apis" annotation,
                //add CRUD apis by default
                if type.hasNoAPIs() && !type.annotations.has(AnnotationConstants.dontGenerateApis) {
                    type.appendAPI(.create)
                    type.appendAPI(.update)
                    type.appendAPI(.delete)
                    type.appendAPI(.getById)
                    type.appendAPI(.list)
                }
            }
        }
        
        return true
    }
}
