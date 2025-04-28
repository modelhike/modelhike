//
//  GenerationLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct GenerationLib {
    
    public static func functions() async -> [Modifier] {
        return await [
            kebabcase(),
            camelcaseToKebabcase(),
            snakecase(),
            identifierCase(),
            packageCase(),
            plural()
        ]
    }
    
    public static func kebabcase() async -> Modifier {
        return await CreateModifier.withoutParams("kebabcase") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForFolderName() }
    }
    
    public static func camelcaseToKebabcase() async -> Modifier {
        return await CreateModifier.withoutParams("split-camel-to-kebabcase") { (value: String, pInfo: ParsedInfo) -> String? in value.camelCaseToKebabCase() }
    }
    
    public static func snakecase() async -> Modifier {
        return await CreateModifier.withoutParams("snakecase") { (value: String, pInfo: ParsedInfo) -> String? in value.camelCaseToSnakeCase() }
    }
    
    public static func identifierCase() async -> Modifier {
        return await CreateModifier.withoutParams("identifier-case") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForVariableName() }
    }
    
    public static func packageCase() async -> Modifier {
        return await CreateModifier.withoutParams("package-case") { (value: String, pInfo: ParsedInfo) -> String? in value.normalizeForPackageName() }
    }
    
    public static func plural() async -> Modifier {
        return await CreateModifier.withoutParams("plural") { (value: String, pInfo: ParsedInfo) -> String? in value.pluralized(count: 2) }
    }
    
}

