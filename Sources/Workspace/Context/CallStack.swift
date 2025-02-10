//
// CallStack.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public protocol CallStackable {
    var callStackItem: CallStackItem { get }
}

public class CallStackItem {
    public let item : FileTemplateStatement
    public let pInfo : ParsedInfo
    
    public init(_ item: FileTemplateStatement, pInfo: ParsedInfo) {
        self.item = item
        self.pInfo = pInfo
    }
}

public class CallStack : Sequence {
    private var stack: [CallStackable] = []
    
    public func push(_ info: CallStackable) {
        stack.append(info)
    }
    
    @discardableResult
    public func popLast() -> CallStackable? {
        return stack.popLast()
    }
    
    public func makeIterator() -> IndexingIterator<[CallStackable]> {
        return stack.reversed().makeIterator()
    }
}
