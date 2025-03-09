//
//  Defaultable.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
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

