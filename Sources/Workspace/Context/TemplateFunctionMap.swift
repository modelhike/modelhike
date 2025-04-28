//
//  TemplateFunctionList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor TemplateFunctionMap: _DictionaryAsyncSequence {
    private var items: [String: TemplateFunction] = [:]

    public init() {
    }

    public func has(_ key: String) -> Bool {
        items.keys.contains(key)
    }

    public func removeValue(forKey key: String) {
        items.removeValue(forKey: key)
    }

    public subscript(key: String) -> TemplateFunction? {
        get { items[key] }
    }
    
    public func set(_ key: String, value newValue: TemplateFunction?) {
        items[key] = newValue
    }
        
    // Capture a snapshot of items (for safe async access)
    public func snapshot() -> [String: Sendable] {
        return items
    }
}
