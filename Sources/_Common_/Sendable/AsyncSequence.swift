//
//  AsyncSequence.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol _DictionaryAsyncSequence: AsyncSequence, Sendable {
    func makeAsyncIterator() -> _DictionaryAsyncIterator
    func snapshot() async -> [String: Sendable]
}

public extension _DictionaryAsyncSequence {
    nonisolated func makeAsyncIterator() -> _DictionaryAsyncIterator {
        _DictionaryAsyncIterator(parent: self)
    }
}

public struct _DictionaryAsyncIterator: AsyncIteratorProtocol {
    private var iterator: Dictionary<String, Sendable>.Iterator?
    private let parent: any _DictionaryAsyncSequence

    public init(parent: any _DictionaryAsyncSequence) {
        self.parent = parent
    }

    public mutating func next() async -> (key: String, value: Sendable)? {
        if iterator == nil {
            iterator = await parent.snapshot().makeIterator()
        }
        return iterator?.next()
    }
}

public protocol _CollectionAsyncSequence: AsyncSequence, Sendable {
    func makeAsyncIterator() -> _CollectionAsyncIterator
    func snapshot() async -> [Sendable]
}

public extension _CollectionAsyncSequence {
    nonisolated func makeAsyncIterator() -> _CollectionAsyncIterator {
        _CollectionAsyncIterator(parent: self)
    }
}

public struct _CollectionAsyncIterator: AsyncIteratorProtocol {
    private var iterator: Array<Sendable>.Iterator?
    private let parent: any _CollectionAsyncSequence

    public init(parent: any _CollectionAsyncSequence) {
        self.parent = parent
    }

    public mutating func next() async -> Sendable? {
        if iterator == nil {
            iterator = await parent.snapshot().makeIterator()
        }
        return iterator?.next()
    }
}
