//
// AnnotationParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum AnnotationParser {
    public static func canParse(firstWord: String) -> Bool {
        return firstWord == ModelConstants.Annotation_Start
    }
    
    public static func parse(pInfo: ParsedInfo) throws -> (any Annotation)? {
        let line = pInfo.line.remainingLine(after: pInfo.firstWord) //remove first word

        let split = line.split(separator: ModelConstants.Annotation_Split, maxSplits: 1, omittingEmptySubsequences: true)
        
        if split.count == 2 {
            let annotationName = split[0].trim()
            let remainingLine = split[1]
            
            switch annotationName {
                case AnnotationConstants.listApi:
                    return try MappingAnnotation(annotationName, line: remainingLine, pInfo: pInfo)
                case AnnotationConstants.apisToGenerate:
                    return try ValuesAnnotation(annotationName, line: remainingLine, pInfo: pInfo)
                default:
                    throw Model_ParsingError.invalidAnnotationLine(pInfo)
            }
        } else {
            throw Model_ParsingError.invalidAnnotationLine(pInfo)
        }
        
    }
}
