//
// Data.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension Data {

    func toHex() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

}
