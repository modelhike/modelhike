//
// GenerationLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerationLib {
    
    public static var functions: [Modifier] {
        return [
            kebabcase,
            camelcaseToKebabcase,
            snakecase,
            identifiercase,
            plural
        ]
    }
    
    public static var kebabcase: Modifier {
        return CreateModifier.withoutParams("kebabcase") { (value: String, lineNo: Int) -> String? in value.normalizeForFolderName() }
    }
    
    public static var camelcaseToKebabcase: Modifier {
        return CreateModifier.withoutParams("split-camel-to-kebabcase") { (value: String, lineNo: Int) -> String? in value.camelCaseToKebabCase() }
    }
    
    public static var snakecase: Modifier {
        return CreateModifier.withoutParams("snakecase") { (value: String, lineNo: Int) -> String? in value.camelCaseToSnakeCase() }
    }
    
    public static var identifiercase: Modifier {
        return CreateModifier.withoutParams("identifiercase") { (value: String, lineNo: Int) -> String? in value.normalizeForVariableName() }
    }
    
    public static var plural: Modifier {
        return CreateModifier.withoutParams("plural") { (value: String, lineNo: Int) -> String? in value.pluralized(count: 2) }
    }
    
}

