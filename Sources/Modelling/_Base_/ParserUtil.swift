//
//  ParserUtil.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ParserUtil {
    public static func populateAttributes(for artifact: HasAttributes_Actor, from attributeString: String) async {
        let attribMatches = attributeString.matches(of: ModelRegEx.attributes_Capturing)
        
        for match in attribMatches {
            let (_, name, value) = match.output
            
            if let value = value { // key-value attribute
                await artifact.attribs.set(name.trim(), value: value)
            } else {
                //add the key as value
                await artifact.attribs.set(name.trim(), value: name.trim())
            }
        }
    }
    
    public static func populateTags(for artifact: HasTags_Actor, from tagString: String) async {
        let tagMatches = tagString.matches(of: ModelRegEx.tags_Capturing)
        
        for match in tagMatches {
            let (_, tag, arg) = match.output
            
            if let arg = arg {
                await artifact.tags.append(tag, arg: arg)
            } else {
                await artifact.tags.append(tag)
            }
        }
    }
    
    public static func extractMixins(for artifact: CodeObject, with ctx: LoadContext) async throws {
        let item = artifact
        try await item.attribs.processEach { attrib in
            if let entity = await ctx.model.types.get(for: attrib.name) {
                await item.append(mixin: entity)
                return nil //remove from attributes, as it is added to mixins
            }
            return attrib
        }
        
        try await item.tags.processEach { tag in
            if tag == TagConstants.savedFrom, let arg = tag.arg {
                if let entity = await ctx.model.types.get(for: arg) {
                    await item.append(mixin: entity)
                }
                return tag
            } else {
                return tag
            }
        }
    }
}

