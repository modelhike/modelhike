//
// ParserUtil.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ParserUtil {
    public static func populateAttributes(for artifact: HasAttributes, from attributeString: String) {
        let attribMatches = attributeString.matches(of: ModelRegEx.attributes_Capturing)
        
        let _ = attribMatches.map( { match in
            let (_, name, value) = match.output
            
            if let value = value { // key-value attribute
                artifact.attribs[name.trim()] = value as Any
            } else {
                //add the key as value
                artifact.attribs[name.trim()] = name.trim()
            }
        })
    }
    
    public static func populateTags(for artifact: HasTags, from tagString: String) {
        let tagMatches = tagString.matches(of: ModelRegEx.tags_Capturing)
        
        let _ = tagMatches.map( { match in
            let (_, tag) = match.output
            artifact.tags.append(String(tag))
        })
    }
    
    public static func extractMixins(for artifact: CodeObject, with ctx: Context) throws {
        let item = artifact
        try item.attribs.processEach { attrib in
            if let entity = ctx.model.types.get(for: attrib.name) {
                item.mixins.append(entity)
                return nil //remove from attributes, as it is added to mixins
            }
            return attrib
        }
    }
}

