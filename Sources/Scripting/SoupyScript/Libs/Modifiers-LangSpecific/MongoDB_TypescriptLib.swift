//
//  MongoDB_TypescriptLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct MongoDB_TypescriptLib {
    public static func functions(sandbox: Sandbox) async -> [Modifier] {
        return await [
            filterString(sandbox: sandbox)
        ]
    }
    
    public static func filterString(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withoutParams("filter-string") { (value: Any, pInfo: ParsedInfo) -> String? in
            
            guard let wrapped = value as? APIParam_Wrap else {
                return nil
            }
            
            let entity = wrapped.item.entity
            let param = wrapped.item.queryParam
            let propMap = wrapped.item.propMaping
            return await self.getFilterString(queryParam: param, propMap: propMap, entity: entity, sandbox: sandbox)
            
        }
    }
    
    private static func getFilterString( queryParam: QueryParam_KeyMapping, propMap: QueryParam_PropertyNameMapping, entity : CodeObject, sandbox: Sandbox) async -> String {
        let canBeMultiple = queryParam.canHaveMultipleValues
        let queryParamName = queryParam.name
        let appModel = await sandbox.model.types
        
        if propMap.hasMultipleMappings { //has multiple property mapping
            guard let prop = await entity.getLastPropInRecursive(propMap.first, appModel: appModel) else {return ""}
            let proptype = await prop.type
            
            return await StringTemplate {
                
                if canBeMultiple {
                    """
                    if (this.\(queryParamName) && [...this.\(queryParamName)]?.length) {

                    """
                } else if (proptype == .string || proptype == .date) {
                    """
                    if (this.\(queryParamName)?.length) {

                    """
                } else {
                    """
                    if (this.\(queryParamName)) {

                    """
                }
                
                """
                    query.set('$or', [
                """
                for singlePropName in propMap.properties {
                    await getIndividualFilterString(queryParam, propName: singlePropName, isSingle: false, entity: entity, sandbox: sandbox)
                }
                """

                    ]);
                        }
                """
            }.string
        
        } else {
            guard let prop = await entity.getLastPropInRecursive(propMap.givenString, appModel: appModel) else {return ""}
            let proptype = await prop.type
            
            return await StringTemplate {
                
                if canBeMultiple {
                    """
                    if (this.\(queryParamName) && [...this.\(queryParamName)]?.length) {

                    """
                } else if (proptype == .string || proptype == .date) {
                    """
                    if (this.\(queryParamName)?.length) {

                    """
                } else {
                    """
                    if (this.\(queryParamName)) {

                    """
                }
 
                await getIndividualFilterString(queryParam, propName: propMap.givenString, isSingle: true, entity: entity, sandbox: sandbox)

                """

                    }
                """
            }.string
        }
    }
    
    private static func getIndividualFilterString(_ queryParam: QueryParam_KeyMapping, propName: String, isSingle: Bool, entity : CodeObject, sandbox: Sandbox) async -> String {
        let canBeMultiple = queryParam.canHaveMultipleValues
        let queryParamName = queryParam.name
        let appModel = await sandbox.model.types

        var isRecursiveProperty = false
        
        //var arrayProp : Property?
        var lastProp : Property!
        var arrayPropName = ""
        var remainingName = ""
        
        var prefix = isSingle ? "query.set('\(propName)'," : "{'\(propName)' :"
        let suffix = isSingle ? ");" : "},"
        
        if propName.hasDot() {
            if let arrayProp = await entity.getArrayPropInRecursive(propName, appModel: appModel),
               let range = await propName.range(of: arrayProp.name) {
                arrayPropName = String(propName[..<range.upperBound])
                remainingName =  String(propName[range.upperBound...].dropFirst()) //drop "."
                
                prefix = isSingle ? "query.set('\(arrayPropName)'," : "{'\(arrayPropName)' :"
            }
            
            lastProp = await entity.getLastPropInRecursive(propName, appModel: appModel)
            isRecursiveProperty = true
        } else {
            lastProp = await entity.getProp(propName)
        }
        
        let lastProp_type_kind = await lastProp.type.kind
        
        return await StringTemplate {
                
            switch lastProp_type_kind {
            case .int, .double :
                let startName = queryParam.name
                let endName = queryParam.SecondName.isNotEmpty ? queryParam.SecondName : queryParam.name

                """
                    const start = this.\(startName);
                    const end = this.\(endName);
                    \(prefix) {
                        $gte: start,
                        $lte: end,
                    }\(suffix)
                """
                
            case .bool:
                """
                    \(prefix) this.\(queryParamName) \(suffix)
                """
            case .id:
                """
                    \(prefix) {
                """
                    if canBeMultiple {
                        """

                                $in: [...this.\(queryParamName)],

                        """
                    } else {
                        """
                                this.\(queryParamName)
                        """
                    }
                        """
                              }
                            \(suffix)
                        """

            case .string:
                    
                if isRecursiveProperty && arrayPropName.isNotEmpty {
                    
                    if remainingName.hasDot() {
                        """
                            \(prefix) {
                                $elemMatch: {
                                    '\(remainingName)': {
                        """
                    } else {
                         """
                            \(prefix) {
                                 $elemMatch: {
                                     \(remainingName): {
                         """
                    }
                    
                    if canBeMultiple {
                        """

                                $in: [...this.\(queryParamName)],

                        """
                    } else {
                        """

                                $regex: this.\(queryParamName),
                                $options: 'i',

                        """
                    }
                    """
                              },
                            },
                          },
                        \(suffix)
                    """
                } else {
                    """
                        \(prefix) {
                    """
                    if canBeMultiple {
                        """

                                $in: [...this.\(queryParamName)],

                        """
                    } else {
                        """

                                $regex: this.\(queryParamName),
                                $options: 'i',

                        """
                    }
                    """
                          }
                        \(suffix)
                    """
                }
                    
            case .date:
                let startName = queryParam.name
                let endName = queryParam.SecondName.isNotEmpty ? queryParam.SecondName : queryParam.name

                """
                    const startDate = new Date(this.\(startName));
                    const endDate = new Date(this.\(endName));
                    endDate.setUTCHours(23, 59, 59, 999);
                    \(prefix) {
                        $gte: startDate,
                        $lte: endDate,
                    }\(suffix)
                """

            case .buffer: ""
            case .reference(_),  .multiReference(_), .extendedReference(_), .multiExtendedReference(_):
                ""
            case .codedValue(_):
                ""
            case .customType(_):
                ""
            default:
                """
                    \(suffix) this.\(queryParamName) \(suffix)
                """
            }
            
            
        }.string
        
    }
}
