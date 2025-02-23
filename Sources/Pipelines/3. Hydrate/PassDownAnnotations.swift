//
// PassDownAnnotationsPass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public struct PassDownAnnotationsPass  : LoadingPass {
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        //process types
        try ws.model.containers.forEach { container in
            
            for type in container.types {
                
                for annotation in type.annotations.annotationsList {
                    try AnnotationProcessor.process(annotation, for: type)
                }
                
            }
        }
        return true
    }
}
