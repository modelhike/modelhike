//
// Defaultable.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Defaultable
{
  init()
}

extension String : Defaultable {
    
}

extension Int : Defaultable {
    
}

extension Double : Defaultable {
    
}

extension Date : Defaultable {
    
}

extension Array : Defaultable {
    
}

extension Dictionary : Defaultable {
    
}

