//
//  AsyncSequence.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol _DictionaryAsyncSequence: AsyncSequence, Sendable {
    associatedtype TSendable: Sendable
    func makeAsyncIterator() -> _DictionaryAsyncIterator<Self>
    func snapshot() async -> [String: TSendable]
}

public extension _DictionaryAsyncSequence {
    nonisolated func makeAsyncIterator() -> _DictionaryAsyncIterator<Self> {
        _DictionaryAsyncIterator(parent: self)
    }
}

public struct _DictionaryAsyncIterator<Parent: _DictionaryAsyncSequence>: AsyncIteratorProtocol {
    private var iterator: Dictionary<String, Parent.TSendable>.Iterator?
    private let parent: Parent

    public init(parent: Parent) {
        self.parent = parent
    }

    public mutating func next() async -> (key: String, value: Parent.TSendable)? {
        if iterator == nil {
            iterator = await parent.snapshot().makeIterator()
        }
        return iterator?.next()
    }
}

public protocol _CollectionAsyncSequence: AsyncSequence, Sendable {
    associatedtype TSendable: Sendable
    func makeAsyncIterator() -> _CollectionAsyncIterator<Self>
    func snapshot() async -> [TSendable]
}

public extension _CollectionAsyncSequence {
    nonisolated func makeAsyncIterator() -> _CollectionAsyncIterator<Self> {
        _CollectionAsyncIterator(parent: self)
    }
}

public struct _CollectionAsyncIterator<Parent: _CollectionAsyncSequence>: AsyncIteratorProtocol {
    private var iterator: Array<Parent.TSendable>.Iterator?
    private let parent: Parent

    public init(parent: Parent) {
        self.parent = parent
    }

    public mutating func next() async -> Parent.TSendable? {
        if iterator == nil {
            iterator = await parent.snapshot().makeIterator()
        }
        return iterator?.next()
    }
}

public protocol _CollectionSequence: Sequence, Sendable {
    associatedtype TSendable: Sendable

    func makeIterator() -> _CollectionIterator<Self>
    func snapshot() -> [TSendable]
}

public extension _CollectionSequence {
    nonisolated func makeIterator() -> _CollectionIterator<Self> {
        _CollectionIterator(parent: self)
    }
}

public struct _CollectionIterator<Parent: _CollectionSequence>: IteratorProtocol {
    private var iterator: Array<Parent.TSendable>.Iterator?
    private let parent: Parent

    public init(parent: Parent) {
        self.parent = parent
    }

    public mutating func next() -> Parent.TSendable? {
        if iterator == nil {
            iterator = parent.snapshot().makeIterator()
        }
        return iterator?.next()
    }
}

extension AsyncSequence {
    @inlinable
    public func compactMap<T>(
        _ transform: @Sendable @escaping (Element) async -> T?
    ) async throws -> [T] {
        var result: [T] = []
        for try await element in self {
            if let transformed = await transform(element) {
                result.append(transformed)
            }
        }
        return result
    }
    
    @inlinable
    public func map<T>(
        _ transform: @Sendable @escaping (Element) async -> T?
    ) async throws -> [T?] {
        var result: [T?] = []
        for try await element in self {
            let transformed = await transform(element)
            result.append(transformed)
        }
        return result
    }
    
    @inlinable
    public func flatMap<T>(
        _ transform: @Sendable (Element) async -> [T]
    ) async throws -> [T] {
        var result: [T] = []
        for try await element in self {
            let transformed = await transform(element)
            result.append(contentsOf: transformed)
        }
        return result
    }
    
    @inlinable
    public func first(where predicate: (Element) async throws -> Bool) async rethrows -> Element? {
        for try await element in self {
            if try await predicate(element) {
                return element
            }
        }
        return nil
    }
}

extension Array {
    @inlinable
    public func compactMap<T>(
        _ transform: @Sendable @escaping (Element)  async -> T?
    ) async  -> [T] {
        var result: [T] = []
        for element in self {
            if let transformed = await transform(element) {
                result.append(transformed)
            }
        }
        return result
    }
    
    @inlinable
    public func map<T>(
        _ transform: @Sendable @escaping (Element) async -> T?
    ) async -> [T?] {
        var result: [T?] = []
        for element in self {
            let transformed = await transform(element)
            result.append(transformed)
        }
        return result
    }
    
    @inlinable
    public func flatMap<T>(
        _ transform: @Sendable (Element) async -> [T]
    ) async -> [T] {
        var result: [T] = []
        for element in self {
            let transformed = await transform(element)
            result.append(contentsOf: transformed)
        }
        return result
    }
    
    @inlinable
    public func first(where predicate: (Element) async -> Bool) async -> Element? {
        for element in self {
            if await predicate(element) {
                return element
            }
        }
        
        return nil
    }
    
    @inlinable
    public func contains(where predicate: (Element) async -> Bool) async -> Bool {
        if let _ = await first(where: predicate) {
            return true
        } else {
            return false
        }
    }
}


