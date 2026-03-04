//
//  InlineBlueprintFinder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

/// A `BlueprintFinder` backed entirely by in-memory `InlineBlueprintLoader`s.
/// Register one or more inline blueprints and add this finder to the
/// `BlueprintAggregator` (or pipeline config) during unit testing.
///
/// Usage:
/// ```swift
/// let finder = InlineBlueprintFinder {
///     InlineBlueprintLoader(name: "my-blueprint") {
///         InlineScript("main", contents: ":render file \"entity.teso\"")
///         InlineTemplate("entity", contents: "class {{ entity.name }} {}")
///     }
/// }
/// await aggregator.add(finder)
/// ```
public actor InlineBlueprintFinder: BlueprintFinder {
    private let loaders: [String: InlineBlueprintLoader]

    public var blueprintsAvailable: [String] { Array(loaders.keys) }

    public func hasBlueprint(named name: String) -> Bool {
        loaders[name] != nil
    }

    public func blueprint(named name: String, with pInfo: ParsedInfo) async throws -> any Blueprint {
        guard let loader = loaders[name] else {
            throw EvaluationError.blueprintDoesNotExist(name, pInfo)
        }
        return loader
    }

    public init(@ResultBuilder<InlineBlueprintLoader> _ builder: () -> [InlineBlueprintLoader]) {
        var map: [String: InlineBlueprintLoader] = [:]
        for loader in builder() {
            map[loader.blueprintName] = loader
        }
        self.loaders = map
    }
}
