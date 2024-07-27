//
// Date.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension DateFormatter {
    convenience init(with format: String) {
        self.init()
        self.calendar = Calendar(identifier: .gregorian)
        self.dateFormat = format
    }
}

public extension Date {
    func adding(days: Int) -> Date {
        let modifiedDate = Calendar.current.date(byAdding: .day, value: days, to: self)!
        return modifiedDate
    }
    
    func removing(days: Int) -> Date {
        let modifiedDate = Calendar.current.date(byAdding: .day, value: -1 * days, to: self)!
        return modifiedDate
    }
}
