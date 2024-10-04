//
// AnnotationProcessor.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum AnnotationProcessor {
    public static func process(_ annotation: any Annotation, for obj: HasAnnotations) throws {
        switch annotation.name {
            case AnnotationConstants.listApi:
                if let cls = obj as? CodeObject {
                    cls.appendAPI(.list)
                }
            case AnnotationConstants.apisToGenerate:
                if let cls = obj as? CodeObject,
                   let valuesAnnotation = annotation as? ValuesAnnotation {
                    for value in valuesAnnotation.values {
                        switch value.lowercased() {
                            case "create": cls.appendAPI(.create)
                            case "update": cls.appendAPI(.update)
                            case "delete": cls.appendAPI(.delete)
                            case "get-by-id": cls.appendAPI(.getById)
                            case "list": cls.appendAPI(.list)
                            case "subscribe, push-data": cls.appendAPI(.pushData)
                            case "subscribe-list, push-datalist": cls.appendAPI(.pushData)
                            case "crud":
                                cls.appendAPI(.create)
                                cls.appendAPI(.update)
                                cls.appendAPI(.delete)
                                cls.appendAPI(.getById)
                                cls.appendAPI(.list)
                            default : break
                        }
                    }
                    
                }
            default:
                throw Model_ParsingError.invalidAnnotation(annotation.parsedContextInfo.lineNo, annotation.parsedContextInfo.line)
        }
    }
}
