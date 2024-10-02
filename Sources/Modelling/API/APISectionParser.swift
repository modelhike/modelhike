//
// APISectionParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum APISectionParser {
    public static func parse(for obj: ArtifactContainer, lineParser parser: LineParser) throws ->  [Artifact] {
        var items : [Artifact] = []
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmptyOrCommented() { parser.skipLine(); continue }

            guard let pctx = parser.currentParsingContext() else { parser.skipLine(); continue }

            if pctx.firstWord == ModelConstants.AttachedSection {
                //either it is the starting of another attached section
                // or it is the end of this attached sections, which is
                // having only '#' in the line
                break
            }
            
            if try pctx.tryParseAnnotations(with: obj) {
                continue
            }
            
            parser.skipLine();
        }
        
        return items
    }
}
