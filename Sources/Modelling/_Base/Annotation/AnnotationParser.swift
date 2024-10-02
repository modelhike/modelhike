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
    
    public static func parse(_ originalLine: String, firstWord: String) throws -> (any Annotation)? {
        let line = originalLine.remainingLine(after: firstWord) //remove first word

        let split = line.split(separator: ModelConstants.Annotation_Split, maxSplits: 1, omittingEmptySubsequences: true)
        
        if split.count == 2 {
            let annotationName = split[0].trim()
            let remainingLine = split[1]
            
            switch annotationName {
                case AnnotationConstants.listApi:
                    return try MappingAnnotation(annotationName, line: remainingLine)
                case AnnotationConstants.apisToGenerate:
                    return try ValuesAnnotation(annotationName, line: remainingLine)
                default:
                    throw Model_ParsingError.invalidAnnotation(originalLine)
            }
        } else {
            throw Model_ParsingError.invalidAnnotation(originalLine)
        }
        
    }
}
