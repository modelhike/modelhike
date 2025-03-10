//
//  AnnotationProcessor.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
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
                var cls: CodeObject?
                
                if let objcls = obj as? CodeObject {
                    cls = objcls
                }

                if let attachedSection = obj as? AttachedSection,
                   let objcls = attachedSection.containingObject as? CodeObject {
                        cls = objcls
                }
            
                if let cls = cls,
                   let valuesAnnotation = annotation as? ValuesAnnotation {
                    for value in valuesAnnotation.values {
                        switch value.lowercased() {
                            case "create": cls.appendAPI(.create)
                            case "update": cls.appendAPI(.update)
                            case "delete": cls.appendAPI(.delete)
                            case "get-by-id": cls.appendAPI(.getById)
                            case "list": cls.appendAPI(.list)
                            case "subscribe", "push-data": cls.appendAPI(.pushData)
                            case "subscribe-list", "push-datalist": cls.appendAPI(.pushData)
                            case "crud":
                                cls.appendAPI(.create)
                                cls.appendAPI(.update)
                                cls.appendAPI(.delete)
                                cls.appendAPI(.getById)
                                cls.appendAPI(.list)
                            case "none":
                                break //nothing to add
                            default :
                            throw Model_ParsingError.invalidAnnotationLine(annotation.pInfo)
                        }
                    }
                    
                }
            default:
            throw Model_ParsingError.invalidAnnotationLine(annotation.pInfo)
        }
    }
}
