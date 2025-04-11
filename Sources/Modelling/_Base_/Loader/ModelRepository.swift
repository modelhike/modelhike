//
//  ModelRepository.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol ModelRepository {
    func loadModel(to model: AppModel) async throws
    func loadGenerationConfigIfAny() async throws
    
    func probeForModelFiles() -> Bool
    func probeForCommonModelFiles() -> Bool
    func probeForGenerationConfig() -> Bool
}

