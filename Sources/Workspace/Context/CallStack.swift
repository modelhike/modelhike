//
//  CallStack.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol CallStackable {
    var callStackItem: CallStackItem { get }
}

public struct SpecialActivityCallStackItem : CallStackable {
    public let callStackItem: CallStackItem
    
    public init(activityName: String) {
        self.callStackItem = CallStackItem(specialActivityName: activityName)
    }
}

public struct CallStackItem {
    public let item : FileTemplateStatement?
    public let pInfo : ParsedInfo?
    public let specialActivityName: String?
    
    public func renderForDisplay() -> String {
        if let pInfo = pInfo {
            return " \(pInfo.identifier) [\(pInfo.lineNo)] \(pInfo.line)"
        } else if let specialActivity = specialActivityName {
            return " \(specialActivity)"
        } else {
            return ""
        }
    }
    
    public init(_ item: FileTemplateStatement, pInfo: ParsedInfo) {
        self.item = item
        self.pInfo = pInfo
        self.specialActivityName = nil
    }
    
    public init(specialActivityName: String) {
        self.specialActivityName = specialActivityName
        self.pInfo = nil
        self.item = nil
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
