//
// InlineModelLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class InlineModelLoader : ModelRepository {    
    let ctx: LoadContext
    public var items : [InlineModelProtocol] = []
    
    public func loadModel(to model: AppModel) throws {
        //first parse the common types
        var commonsString = ""
        
        for item in items {
            if let commonsItem = item as? InlineCommonTypes {
                commonsString += commonsItem.string
            }
        }
        
        //common models
        let commons = try ModelFileParser( with: ctx)
                        .parse(string: commonsString, identifier: "InlineCommons")
        
        model.appendToCommonModel(contentsOf: commons)
        
        //parse rest of the models
        for item in items {
            if let modelItem = item as? InlineModel {
                let modelSpace = try ModelFileParser(with: ctx)
                    .parse(string: modelItem.string, identifier: "InlineDomain")
                
                model.append(contentsOf: modelSpace)
            }
        }
        
        try model.resolveAndLinkItems(with: ctx)
    }
    
    public func loadGenerationConfigIfAny() throws {
        for item in items {
            if let modelConfig = item as? InlineConfig {
                try ConfigFileParser(with: ctx)
                    .parse(string: modelConfig.string, identifier: "config")
                
            }
        }
    }
    
    public init(with ctx: LoadContext, @InlineModelBuilder _ builder: () -> [InlineModelProtocol]) {
        self.ctx = ctx
        self.items = builder()
    }
}

public struct InlineModel : InlineModelProtocol {
    public var items: [StringConvertible] = []

    public init(@StringConvertibleBuilder _ builder : () -> [StringConvertible]) {
        items = builder()
    }
}

public struct InlineCommonTypes : InlineModelProtocol {
    public var items: [StringConvertible] = []

    public init(@StringConvertibleBuilder _ builder : () -> [StringConvertible]) {
        items = builder()
    }
}
    
public struct InlineConfig : InlineModelProtocol {
    public var items: [StringConvertible] = []
    
    public init(@StringConvertibleBuilder _ builder : () -> [StringConvertible]) {
        items = builder()
    }
}

public protocol InlineModelProtocol {
    var items: [StringConvertible] { get set}
    var string: String {get}
}

public extension InlineModelProtocol {
    var string: String {
        return items.reduce("") { $0 + $1.toString() }
    }
}

typealias InlineModelBuilder = ResultBuilder<InlineModelProtocol>
