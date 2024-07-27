//
// Template.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Template : StringConvertible { }

public protocol PlaceHolderTemplate : Template{ }

public protocol ScriptedTemplate :Template { }

public protocol ProgrammedTemplate : Template { }
