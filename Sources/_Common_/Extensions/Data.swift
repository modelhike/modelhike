//
//  Data.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

extension Data {

    public func toHex() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

}
