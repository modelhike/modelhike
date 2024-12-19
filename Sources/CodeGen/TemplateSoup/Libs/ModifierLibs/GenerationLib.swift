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
            identifierCase,
            packageCase,
            plural
        ]
    }
    
    public static var kebabcase: Modifier {
        return CreateModifier.withoutParams("kebabcase") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForFolderName() }
    }
    
    public static var camelcaseToKebabcase: Modifier {
        return CreateModifier.withoutParams("split-camel-to-kebabcase") { (value: String, pInfo: ParsedInfo) -> String? in value.camelCaseToKebabCase() }
    }
    
    public static var snakecase: Modifier {
        return CreateModifier.withoutParams("snakecase") { (value: String, pInfo: ParsedInfo) -> String? in value.camelCaseToSnakeCase() }
    }
    
    public static var identifierCase: Modifier {
        return CreateModifier.withoutParams("identifier-case") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForVariableName() }
    }
    
    public static var packageCase: Modifier {
        return CreateModifier.withoutParams("package-case") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForPackageName() }
    }
    
    public static var plural: Modifier {
        return CreateModifier.withoutParams("plural") { (value: String, pInfo: ParsedInfo) -> String? in value.pluralized(count: 2) }
    }
    
}

