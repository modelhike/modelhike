//
// TemplateFunctionList.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public class TemplateFunctionMap: Sequence, IteratorProtocol {
    private var iterator: Dictionary<String, TemplateFunctionContainer>.Iterator?
    private var items: [String: TemplateFunctionContainer] = [:]
    
    public init() {
        resetIterator()
    }

    public func has(_ key: String) -> Bool {
        items.keys.contains(key)
    }

    public func removeValue(forKey key: String) {
        items.removeValue(forKey: key)
        resetIterator() // Reset iterator when data changes
    }

    public subscript(key: String) -> TemplateFunctionContainer? {
        get { items[key] }
        set {
            items[key] = newValue
            resetIterator() // Reset iterator when data changes
        }
    }

    public func next() -> (key: String, value: Any)? {
        return iterator?.next()
    }

    public func makeIterator() -> TemplateFunctionMap {
        resetIterator()
        return self
    }

    // Reset the iterator to allow fresh iteration
    private func resetIterator() {
        iterator = items.makeIterator()
    }
}
