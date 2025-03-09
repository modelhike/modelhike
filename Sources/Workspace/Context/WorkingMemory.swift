//
//  WorkingMemory.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public class WorkingMemory: Sequence, IteratorProtocol {
    private var iterator: Dictionary<String, Any>.Iterator?
    private var items: [String: Any] = [:]

    public func replace(variables: StringDictionary) {
        self.items = variables
    }

    public func replace(variables: WorkingMemory) {
        self.items = variables.items
    }

    public init() {
        resetIterator()
    }

    public func has(_ key: String) -> Bool {
        items.keys.contains(key)
    }

    public func removeValue(forKey key: String) {
        items.removeValue(forKey: key)
        resetIterator()  // Reset iterator when data changes
    }

    public subscript(key: String) -> Any? {
        get { items[key] }
        set {
            items[key] = newValue
            resetIterator()  // Reset iterator when data changes
        }
    }

    public func next() -> (key: String, value: Any)? {
        return iterator?.next()
    }

    public func makeIterator() -> WorkingMemory {
        resetIterator()
        return self
    }

    // Reset the iterator to allow fresh iteration
    private func resetIterator() {
        iterator = items.makeIterator()
    }
}
