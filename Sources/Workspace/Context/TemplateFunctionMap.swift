//
//  TemplateFunctionList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor TemplateFunctionMap: _DictionaryAsyncSequence {
    private var items: [String: TemplateFunctionContainer] = [:]

    public init() {
    }

    public func has(_ key: String) -> Bool {
        items.keys.contains(key)
    }

    public func removeValue(forKey key: String) {
        items.removeValue(forKey: key)
    }

    public subscript(key: String) -> TemplateFunctionContainer? {
        get { items[key] }
        set {
            items[key] = newValue
        }
    }

    // Capture a snapshot of items (for safe async access)
    public func snapshot() -> [String: Sendable] {
        return items
    }
}
