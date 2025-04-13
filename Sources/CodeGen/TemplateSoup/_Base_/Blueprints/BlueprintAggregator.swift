//
//  BlueprintAggregator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor BlueprintAggregator: Sendable {
    var blueprintFinders: [BlueprintFinder] = []

    public func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint {
        for finder in blueprintFinders {
            if finder.hasBlueprint(named: name) {
                return try finder.blueprint(named: name, with: pInfo)
            }
        }

        throw EvaluationError.blueprintDoesNotExist(name, pInfo)
    }

    @discardableResult
    public func add(_ finder: BlueprintFinder) -> Bool {
        blueprintFinders.append(finder)
        return true
    }

    public init() {}
}
