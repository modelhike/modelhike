//
// BlueprintAggregator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public class BlueprintAggregator {
    var blueprintFinders: [BlueprintFinder] = []
    
    public func blueprint(named name: String, with pInfo: ParsedInfo) throws -> any Blueprint {
        for finder in blueprintFinders {
            if finder.hasBlueprint(named: name) {
                return try finder.blueprint(named: name, with: pInfo)
            }
        }
        
        throw EvaluationError.invalidInput("There is no blueprint called \(name)", pInfo)
    }
    
    @discardableResult
    public func add(_ finder: BlueprintFinder) -> Bool {
        blueprintFinders.append(finder)
        return true
    }
    
    public init() { }
}
