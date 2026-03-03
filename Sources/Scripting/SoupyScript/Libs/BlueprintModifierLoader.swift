//
//  BlueprintModifierLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Scans the `_modifiers_/` folder inside the active blueprint for `.teso` files and
/// converts each one into a registered `Modifier`.
///
/// ## Front-matter schema (YAML-style, inside `---` fences)
///
/// ```
/// ---
/// input: value          # variable name the piped value is bound to in the template
/// type: String          # expected input type: String | Double | Bool | Array | Object | Any
/// params: from, to      # (optional) comma-separated names for positional arguments
/// ---
/// ```
///
/// - If **no front matter** is present, defaults are used: `input = "value"`, `type = Any`, no params.
/// - If `params` is absent or empty, a `BlueprintModifierWithoutParams` is registered.
/// - If `params` is present, a `BlueprintModifierWithParams` is registered — the modifier
///   must be invoked as `{{ value | modifierName(arg1, arg2) }}`.
public struct BlueprintModifierLoader {

    /// Loads all blueprint-defined modifiers from the `_modifiers_/` special folder.
    ///
    /// - Parameters:
    ///   - blueprint: The active blueprint source (local file loader or resource bundle).
    ///   - templateSoup: The `TemplateSoup` instance used to render modifier templates at call time.
    ///   - pInfo: Parsing context for error reporting and front-matter evaluation.
    /// - Returns: An array of `Modifier` values ready to be registered in `TemplateSoupSymbols`.
    public static func loadModifiers(
        from blueprint: any Blueprint,
        templateSoup: TemplateSoup,
        with pInfo: ParsedInfo
    ) async throws -> [Modifier] {
        guard await blueprint.hasFolder(SpecialFolderNames.modifiers) else { return [] }

        let filenames = await blueprint.listFiles(inFolder: SpecialFolderNames.modifiers)
        var modifiers: [Modifier] = []

        let templateFileExtension = ".\(TemplateConstants.TemplateExtension)"

        for filename in filenames {
            guard filename.hasSuffix(templateFileExtension) else { continue }

            let relativePath = "\(SpecialFolderNames.modifiers)/\(filename)"
            let contents = try await blueprint.readTextContents(filename: relativePath, with: pInfo)
            let name = String(filename.dropLast(templateFileExtension.count))

            if let modifier = buildModifier(name: name, contents: contents, templateSoup: templateSoup) {
                modifiers.append(modifier)
            }
        }

        return modifiers
    }

    // MARK: - Private helpers

    private static func buildModifier(
        name: String,
        contents: String,
        templateSoup: TemplateSoup
    ) -> Modifier? {
        let (fm, body)   = FrontMatter.parse(contents: contents)
        let inputVarName = fm["input"] ?? "value"
        let inputType    = BlueprintModifierInputType(string: fm["type"])
        let paramNames   = (fm["params"] ?? "").split(separator: ",")
                                                         .compactMap { $0.trim().nonEmpty }

        if paramNames.isEmpty {
            return BlueprintModifierWithoutParams(
                name: name, templateContents: body,
                inputVarName: inputVarName, inputType: inputType, templateSoup: templateSoup)
        } else {
            return BlueprintModifierWithParams(
                name: name, templateContents: body,
                inputVarName: inputVarName, inputType: inputType,
                paramNames: paramNames, templateSoup: templateSoup)
        }
    }
}
