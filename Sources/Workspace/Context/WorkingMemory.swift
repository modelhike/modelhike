//
//  WorkingMemory.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public actor WorkingMemory: _DictionaryAsyncSequence {
    private var items: [String: Sendable] = [:]

    public func replace(variables: [String: Sendable]) {
        self.items = variables
    }

    public func replace(variables: WorkingMemory) async {
        self.items = await variables.snapshot()
    }

    public init() {
    }

    public func has(_ key: String) -> Bool {
        items.keys.contains(key)
    }

    public func removeValue(forKey key: String) {
        items.removeValue(forKey: key)
    }

    public subscript(key: String) -> Sendable? {
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

