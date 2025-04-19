//
//  PassDownAndProcessAnnotationsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor PassDownAndProcessAnnotationsPass: LoadingPass {
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        
        //pass the annotations of the component to its child items
        await ws.model.containers.forEach { container in
            
            for type in await container.types {
                await type.annotations.append(contentsOf: container.annotations)
            }
            
        }
        
        //process annotation for types
        try await ws.model.containers.forEach { container in
            
            for type in await container.types {
                
                for annotation in await type.annotations.annotationsList {
                    try await AnnotationProcessor.process(annotation, for: type)
                }
                
                //after processing, if the type has not apis,
                //if it is not marked with "@no-apis" annotation,
                //add CRUD apis by default
                let dontGenerateAPIs = await type.annotations.has(AnnotationConstants.dontGenerateApis)
                if await type.hasNoAPIs() && !dontGenerateAPIs {
                    await type.appendAPI(.create)
                    await type.appendAPI(.update)
                    await type.appendAPI(.delete)
                    await type.appendAPI(.getById)
                    await type.appendAPI(.list)
                }
            }
        }
        
        return true
    }
}
