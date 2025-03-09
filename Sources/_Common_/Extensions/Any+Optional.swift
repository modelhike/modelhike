//
//  Any+Optional.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

fileprivate protocol FlattenableOptional {
  func flattened() -> Any?
}

extension Optional: FlattenableOptional {
  func flattened() -> Any? {
    switch self {
    case .some(let x as FlattenableOptional): return x.flattened()
    case .some(let x): return x
    case .none: return nil
    }
  }
}

internal func deepUnwrap(_ any: Any) -> Any? {
    if let optional = any as? FlattenableOptional {
        return optional.flattened()
    }
    return any
}
