//
// ModelRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol ModelRepository {
    func loadModel(to model: AppModel) throws
    func loadGenerationConfigIfAny() throws
}

