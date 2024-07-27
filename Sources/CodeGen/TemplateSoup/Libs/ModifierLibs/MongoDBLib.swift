//
// MongoDbLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct MongoDBLib {
    public static func functions(sandbox: Sandbox) -> [Modifier] {
        return [
            filterString(sandbox: sandbox)
        ]
    }
    
    public static func filterString(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("filter-string") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? APIParam_Wrap else {
                return nil
            }
            
            let entity = wrapped.item.entity
            let param = wrapped.item.queryParam
            let propMap = wrapped.item.propMaping
            return self.getFilterString(queryParam: param, propMap: propMap, entity: entity, sandbox: sandbox)
            
        }
    }
    
    private static func getFilterString( queryParam: QueryParam, propMap: PropNameMapping, entity : CodeObject, sandbox: Sandbox) -> String {
        let canBeMultiple = queryParam.canHaveMultipleValues
        let queryParamName = queryParam.name
        let appModel = sandbox.model.parsedModel
        
        if propMap.hasMultipleMappings { //has multiple property mapping
            guard let prop = entity.getLastPropInRecursive(propMap.first, appModel: appModel) else {return ""}

            return StringTemplate {
                
                if canBeMultiple {
                    """
                    if (this.\(queryParamName) && [...this.\(queryParamName)]?.length) {

                    """
                } else if (prop.type == .string || prop.type == .date) {
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
                    getIndividualFilterString(queryParam, propName: singlePropName, isSingle: false, entity: entity, sandbox: sandbox)
                }
                """

                    ]);
                        }
                """
            }.string
        
        } else {
            guard let prop = entity.getLastPropInRecursive(propMap.givenString, appModel: appModel) else {return ""}

            return StringTemplate {
                
                if canBeMultiple {
                    """
                    if (this.\(queryParamName) && [...this.\(queryParamName)]?.length) {

                    """
                } else if (prop.type == .string || prop.type == .date) {
                    """
                    if (this.\(queryParamName)?.length) {

                    """
                } else {
                    """
                    if (this.\(queryParamName)) {

                    """
                }
 
                getIndividualFilterString(queryParam, propName: propMap.givenString, isSingle: true, entity: entity, sandbox: sandbox)

                """

                    }
                """
            }.string
        }
    }
    
    private static func getIndividualFilterString(_ queryParam: QueryParam, propName: String, isSingle: Bool, entity : CodeObject, sandbox: Sandbox) -> String {
        let canBeMultiple = queryParam.canHaveMultipleValues
        let queryParamName = queryParam.name
        let appModel = sandbox.model.parsedModel

        var isRecursiveProperty = false
        
        //var arrayProp : Property?
        var lastProp : Property!
        var arrayPropName = ""
        var remainingName = ""
        
        var prefix = isSingle ? "query.set('\(propName)'," : "{'\(propName)' :"
        let suffix = isSingle ? ");" : "},"
        
        if propName.hasDot() {
            if let arrayProp = entity.getArrayPropInRecursive(propName, appModel: appModel),
                let range = propName.range(of: arrayProp.name) {
                arrayPropName = String(propName[..<range.upperBound])
                remainingName =  String(propName[range.upperBound...].dropFirst()) //drop "."
                
                prefix = isSingle ? "query.set('\(arrayPropName)'," : "{'\(arrayPropName)' :"
            }
            
            lastProp = entity.getLastPropInRecursive(propName, appModel: appModel)
            isRecursiveProperty = true
        } else {
            lastProp = entity.getProp(propName)
        }
        
        return StringTemplate {
                
            switch lastProp.type {
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
