//
//  AnnotationProcessor.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum AnnotationProcessor {
    public static func process(_ annotation: any Annotation, for obj: HasAttributes_Actor) async throws {
        switch annotation.name {
            case AnnotationConstants.listApi:
                if let cls = obj as? CodeObject {
                    await cls.appendAPI(.list)
                }
            case AnnotationConstants.apisToGenerate:
                var cls: CodeObject?
                
                if let objcls = obj as? CodeObject {
                    cls = objcls
                }

                if let attachedSection = obj as? AttachedSection,
                   let objcls = await attachedSection.containingObject as? CodeObject {
                        cls = objcls
                }
            
                if let cls = cls,
                   let valuesAnnotation = annotation as? ValuesAnnotation {
                    for value in valuesAnnotation.values {
                        switch value.lowercased() {
                        case "create": await cls.appendAPI(.create)
                        case "update": await cls.appendAPI(.update)
                        case "delete": await cls.appendAPI(.delete)
                        case "get-by-id": await cls.appendAPI(.getById)
                        case "list": await cls.appendAPI(.list)
                        case "subscribe", "push-data": await cls.appendAPI(.pushData)
                        case "subscribe-list", "push-datalist": await cls.appendAPI(.pushData)
                        case "crud":
                            await cls.appendAPI(.create)
                            await cls.appendAPI(.update)
                            await cls.appendAPI(.delete)
                            await cls.appendAPI(.getById)
                            await cls.appendAPI(.list)
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
