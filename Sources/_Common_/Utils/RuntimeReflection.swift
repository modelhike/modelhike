//
//  RuntimeReflection.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public struct RuntimeReflection {
    public static func getValueOf(property hierarchicalKeyPath: String, in object: Any, with pInfo: ParsedInfo) -> Any? {
        let keys = hierarchicalKeyPath.split(separator: ".").map(String.init)
        return getValue(from: object, keys: keys)
    }

    private static func getValue(from object: Any, keys: [String]) -> Any? {
        guard let firstKey = keys.first else { return object }
        let mirror = Mirror(reflecting: object)
        
        for child in mirror.children {
            if child.label == firstKey {
                if keys.count == 1 {
                    return child.value
                } else {
                    return getValue(from: child.value, keys: Array(keys.dropFirst()))
                }
            }
        }
        
        return nil // Return nil if the key path does not exist
    }
    
    //FIXME: test
    @discardableResult
    public static func setValue(_ value: Any, forProperty hierarchicalKeyPath: String, in object: inout Any, with pInfo: ParsedInfo) throws -> Bool {
        throw ParsingError.featureNotImplementedYet(pInfo)
//        var keys = hierarchicalKeyPath.split(separator: ".").map(String.init)
//        guard let lastKey = keys.popLast() else { return false }
//        return setValue(value, for: lastKey, in: &object, keys: keys)
    }

//    private static func setValue(_ value: Any, for key: String, in object: inout Any, keys: [String]) -> Bool {
//        if keys.isEmpty {
//            // Base case: Set the value directly
//            let mirror = Mirror(reflecting: object)
//            guard var child = mirror.children.first(where: { $0.label == key }) else { return false }
//            child.value = value
//            return true
//
//        } else {
//            // Recursive case: Drill down into the hierarchy
//            let mirror = Mirror(reflecting: object)
//            guard let child = mirror.children.first(where: { $0.label == keys.first }) else { return false }
//            
//            var childValue = child.value
//            let success = setValue(value, for: key, in: &childValue, keys: Array(keys.dropFirst()))
//            
//            // Reassign the updated child back to the parent
//            if success {
//                object = childValue
//                return true
//            }
//        }
//        return false
//    }
}
