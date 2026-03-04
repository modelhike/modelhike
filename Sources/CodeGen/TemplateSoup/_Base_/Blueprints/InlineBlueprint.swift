//
//  InlineBlueprint.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// An in-memory `Blueprint` for use in unit tests.
/// Mirrors the role of `InlineModelLoader` for the model layer.
///
/// ```swift
/// let blueprint = InlineBlueprint(name: "api-blueprint") {
///     InlineScript("main", contents: ":render file \"Entity.teso\"")
///
///     InlineFolder("_root_") {
///         InlineTemplate("Entity", contents: "class {{ entity.name }} {}")
///     }
///
///     InlineModifier("javaType", contents: """
///         ---
///         input: prop
///         type: Object
///         ---
///         String
///         """)
/// }
/// ```
public actor InlineBlueprint: Blueprint {
    public let blueprintName: String

    /// `[foldername: [filename_with_ext: contents]]` — root items use key `""`.
    private let folderMap: [String: [String: String]]

    // MARK: Blueprint

    public func exists() -> Bool { true }

    public func loadTemplate(fileName: String, with pInfo: ParsedInfo) throws -> Template {
        let fullName = "\(fileName).\(TemplateConstants.TemplateExtension)"
        guard let contents = folderMap[""]?[fullName] else {
            throw TemplateSoup_EvaluationError.templateDoesNotExist(fileName, pInfo)
        }
        return StringTemplate(contents: contents, name: fileName)
    }

    public func loadScriptFile(fileName: String, with pInfo: ParsedInfo) throws -> any Script {
        let fullName = "\(fileName).\(TemplateConstants.ScriptExtension)"
        guard let contents = folderMap[""]?[fullName] else {
            throw TemplateSoup_EvaluationError.scriptFileDoesNotExist(fileName, pInfo)
        }
        return StringTemplate(contents: contents, name: fileName)
    }

    // MARK: InputFileRepository

    public func readTextContents(filename: String, with pInfo: ParsedInfo) throws -> String {
        let (folder, file) = splitPath(filename)
        guard let contents = folderMap[folder]?[file] else {
            throw TemplateSoup_EvaluationError.templateReadingError(filename, pInfo)
        }
        return contents
    }

    public func hasFolder(_ foldername: String) -> Bool {
        folderMap[foldername] != nil
    }

    public func listFiles(inFolder foldername: String) -> [String] {
        guard let files = folderMap[foldername] else { return [] }
        return Array(files.keys)
    }

    public func copyFiles(foldername: String, to folder: OutputFolder, with pInfo: ParsedInfo) async throws {
        // No real bytes to copy for in-memory blueprints — intentional no-op.
    }

    public func renderFiles(
        foldername: String, to outputFolder: OutputFolder,
        using templateSoup: TemplateSoup, with pInfo: ParsedInfo
    ) async throws {
        guard let files = folderMap[foldername] else { return }

        for (filename, contents) in files {
            guard filename.hasSuffix(".\(TemplateConstants.TemplateExtension)") else { continue }

            let actualName = String(filename.dropLast(".\(TemplateConstants.TemplateExtension)".count))
            if let rendered = try await templateSoup.renderTemplate(
                string: contents, identifier: actualName, with: pInfo)
            {
                let outFile = TemplateRenderedFile(filename: actualName, contents: rendered, pInfo: pInfo)
                await outputFolder.add(outFile)
            }
        }
    }

    // MARK: Init

    public init(
        name: String = "inline-blueprint",
        @InlineBlueprintItemBuilder _ builder: () -> [any InlineBlueprintItem]
    ) {
        self.blueprintName = name
        var map: [String: [String: String]] = [:]
        for item in builder() {
            var folderFiles = map[item.foldername] ?? [:]
            folderFiles[item.filename] = item.contents
            map[item.foldername] = folderFiles
        }
        self.folderMap = map
    }

    // MARK: Private helpers

    /// Splits `"_modifiers_/javaType.teso"` → `("_modifiers_", "javaType.teso")`.
    /// Files without a path separator are treated as root-level → `("", filename)`.
    private func splitPath(_ path: String) -> (folder: String, file: String) {
        guard let slashIndex = path.firstIndex(of: "/") else { return ("", path) }
        return (String(path[..<slashIndex]), String(path[path.index(after: slashIndex)...]))
    }
}

// MARK: - Item protocol

/// Represents a single in-memory file inside a blueprint (template, script, or modifier).
public protocol InlineBlueprintItem: Sendable {
    /// Folder within the blueprint. Use `""` for root-level files.
    var foldername: String { get }
    /// Filename including extension (e.g. `"main.teso"`, `"main.ss"`).
    var filename: String { get }
    var contents: String { get }
}

// MARK: - Concrete item types

/// An in-memory `.teso` template file at the blueprint root (or an explicit folder).
/// The `.teso` extension is appended automatically.
public struct InlineTemplate: InlineBlueprintItem {
    public let foldername: String
    public let filename: String
    public let contents: String

    public init(_ name: String, in folder: String = "", contents: String) {
        self.foldername = folder
        self.filename   = "\(name).\(TemplateConstants.TemplateExtension)"
        self.contents   = contents
    }
}

/// An in-memory `.ss` script file at the blueprint root (or an explicit folder).
/// The `.ss` extension is appended automatically.
public struct InlineScript: InlineBlueprintItem {
    public let foldername: String
    public let filename: String
    public let contents: String

    public init(_ name: String, in folder: String = "", contents: String) {
        self.foldername = folder
        self.filename   = "\(name).\(TemplateConstants.ScriptExtension)"
        self.contents   = contents
    }
}

/// Shorthand for a blueprint-defined modifier: a `.teso` file placed in `_modifiers_`.
/// The `.teso` extension is appended automatically.
///
/// Example:
/// ```swift
/// InlineModifier("javaType", contents: """
///     ---
///     input: prop
///     type: Object
///     ---
///     String
///     """)
/// ```
public struct InlineModifier: InlineBlueprintItem {
    public let foldername = SpecialFolderNames.modifiers
    public let filename: String
    public let contents: String

    public init(_ name: String, contents: String) {
        self.filename = "\(name).\(TemplateConstants.TemplateExtension)"
        self.contents = contents
    }
}

/// Groups multiple inline items under a named sub-folder of the blueprint.
///
/// Example:
/// ```swift
/// InlineFolder("_root_") {
///     InlineTemplate("Entity", contents: "class {{ entity.name }} {}")
/// }
/// ```
public struct InlineFolder: Sendable {
    fileprivate let items: [any InlineBlueprintItem]

    public init(_ name: String, @InlineBlueprintItemBuilder _ builder: () -> [any InlineBlueprintItem]) {
        self.items = builder().map { FolderScopedItem(foldername: name, from: $0) }
    }
}

/// Private wrapper that overrides `foldername` on an existing item.
private struct FolderScopedItem: InlineBlueprintItem {
    let foldername: String
    let filename: String
    let contents: String

    init(foldername: String, from item: any InlineBlueprintItem) {
        self.foldername = foldername
        self.filename   = item.filename
        self.contents   = item.contents
    }
}

// MARK: - Builder

/// A result builder that accepts `InlineBlueprintItem`-conforming values **and**
/// `InlineFolder` containers (which expand to multiple items with a shared folder name).
@resultBuilder
public struct InlineBlueprintItemBuilder {
    public static func buildBlock(_ components: [any InlineBlueprintItem]...) -> [any InlineBlueprintItem] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: any InlineBlueprintItem) -> [any InlineBlueprintItem] {
        [expression]
    }

    public static func buildExpression(_ expression: InlineFolder) -> [any InlineBlueprintItem] {
        expression.items
    }

    public static func buildOptional(_ component: [any InlineBlueprintItem]?) -> [any InlineBlueprintItem] {
        component ?? []
    }

    public static func buildEither(first component: [any InlineBlueprintItem]) -> [any InlineBlueprintItem] {
        component
    }

    public static func buildEither(second component: [any InlineBlueprintItem]) -> [any InlineBlueprintItem] {
        component
    }

    public static func buildArray(_ components: [[any InlineBlueprintItem]]) -> [any InlineBlueprintItem] {
        components.flatMap { $0 }
    }
}


