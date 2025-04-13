//
//  APISectionParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public enum APISectionParser {
    public static func parse(for obj: CodeObject, lineParser parser: LineParser) async throws
        -> [Artifact]
    {
        var apis: [Artifact] = []

        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() {
                await parser.skipLine()
                continue
            }

            guard let pInfo = await parser.currentParsedInfo(level: 0) else {
                await parser.skipLine()
                continue
            }

            if pInfo.firstWord == ModelConstants.AttachedSection {
                //either it is the starting of another attached section
                // or it is the end of this attached sections, which is
                // having only '#' in the line
                break
            }

            if try await pInfo.tryParseAnnotations(with: obj) {
                continue
            }

            if pInfo.firstWord == ModelConstants.AttachedSubSection {
                let line = pInfo.line.dropFirstWord().lowercased()

                if let match = line.wholeMatch(of: Self.customListApi_WithCondition_Regex) {
                    let (_, prop1, op, prop2) = match.output

                    let api = ListAPIByCustomProperties(entity: obj)

                    if op.trim().lowercased() == "and" {
                        api.andCondition = true
                    }

                    if let property1 = await obj.getProp(prop1.trim(), isCaseSensitive: false) {
                        api.properties.append(property1)
                    } else {
                        throw Model_ParsingError.invalidPropertyUsedInApi(prop1, pInfo)
                    }

                    if let property2 = await obj.getProp(prop2.trim(), isCaseSensitive: false) {
                        api.properties.append(property2)
                    } else {
                        throw Model_ParsingError.invalidPropertyUsedInApi(prop2, pInfo)
                    }

                    apis.append(api)

                } else if let match = line.wholeMatch(of: Self.customListApi_SingleProperty_Regex) {
                    let (_, prop1) = match.output

                    let api = ListAPIByCustomProperties(entity: obj)

                    if let property1 = await obj.getProp(prop1.trim(), isCaseSensitive: false) {
                        api.properties.append(property1)
                    } else {
                        throw Model_ParsingError.invalidPropertyUsedInApi(prop1, pInfo)
                    }

                    apis.append(api)
                } else if let method = try await MethodObject.parse(pInfo: pInfo, skipLine: false) {
                    //custom logic api is defined using method syntax
                    let api = CustomLogicAPI(method: method, entity: obj)
                    apis.append(api)
                } else {
                    throw Model_ParsingError.invalidApiLine(pInfo)
                }

            }

            await parser.skipLine()
        }

        return apis
    }

    nonisolated(unsafe)
    static let customListApi_SingleProperty_Regex = Regex {
        "list by"

        CommonRegEx.whitespace
        Capture {
            CommonRegEx.nameWithWhitespace
        } transform: {
            String($0)
        }

        CommonRegEx.comments
    }

    nonisolated(unsafe)
    static let customListApi_WithCondition_Regex = Regex {
        "list by"

        CommonRegEx.whitespace
        Capture {
            CommonRegEx.nameWithWhitespace
        } transform: {
            String($0)
        }

        CommonRegEx.whitespace

        Capture {
            ChoiceOf {
                "and"
                "or"
            }
        } transform: {
            String($0)
        }

        CommonRegEx.whitespace
        Capture {
            CommonRegEx.nameWithWhitespace
            Optionally("[]")
        } transform: {
            String($0)
        }

        CommonRegEx.comments
    }
}
