//
//  AttachedSectionParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum AttachedSectionParser {
    // Attached Section start should be of the format:
    //
    // # attached section code
    public static func canParse(firstWord: String) -> Bool {
            
        if firstWord.isOnly(ModelConstants.AttachedSection) {
            return true
        }
        
        return false
    }
    
    public static func parse(for obj: ArtifactHolderWithAttachedSections, with pctx: ParsedInfo) async throws -> AttachedSection? {
        let line = pctx.line.dropFirstWord()
        guard let match = line.wholeMatch(of: ModelRegEx.attachedSectionName_Capturing)                                                                                  else { return nil }
        
        let (_, sectionCode, attributeString, tagString) = match.output
        let item = AttachedSection(code: sectionCode.trim(), for: obj)
        
        //check if has attributes
        if let attributeString = attributeString {
            await ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: item, from: tagString)
        }
        
        let parser = pctx.parser
        await parser.skipLine()//skip attached section name
         
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }
            
            guard let pctx = await parser.currentParsedInfo(level: pctx.level) else { await parser.skipLine(); continue }
            
            if try await pctx.tryParseAnnotations(with: item) {
                continue
            }
            
            let attachedItems = try await pctx.parseAttachedItems(for: obj, with: item)
            for attachedItem in attachedItems {
                await obj.appendAttached(attachedItem)
            }
            
            if pctx.firstWord == ModelConstants.AttachedSection {
                //either it is the starting of another attached section
                // or it is the end of this attached sections, which is
                // having only '#' in the line
                
                if pctx.line.secondWord() == nil { //marks end of attached section
                    await parser.skipLine()
                }
                
                break
            }
        }
        
        return item
    }
}
