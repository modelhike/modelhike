//
//  SnapshotStack.swift
//  DiagSoup
//
//  Created by Hari on 01/03/25.
//


public class SnapshotStack : Sequence {
    private var stack: [ContextState] = []
    
    public func push(_ info: ContextState) {
        stack.append(info)
    }
    
    public func append(_ info: ContextState) {
        stack.append(info)
    }
    
    @discardableResult
    public func popLast() -> ContextState? {
        return stack.popLast()
    }
    
    public func makeIterator() -> IndexingIterator<[ContextState]> {
        return stack.makeIterator()
    }
}
