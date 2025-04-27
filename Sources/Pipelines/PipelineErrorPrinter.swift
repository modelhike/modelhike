//
//  PipelineErrorPrinter.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public struct PipelineErrorPrinter {
    func printError(_ err: Error, context: Context) async {
        let stack = await context.debugLog.stack.snapshot()
        let includeMemoryVariablesDump = await context.config.errorOutput.includeMemoryVariablesDump
        
        let callStackInfo = StringTemplate {
            "[Call Stack]"
            
            for log in stack {
                String.newLine
                log.callStackItem.renderForDisplay()
            }
        }
        
        let memoryVarsInfo = await StringTemplate {
            "[Memory]"
            
            await dumpMemory(context: context)
        }
        
        let extraInfo = StringTemplate {
            callStackInfo
            
            if includeMemoryVariablesDump {
                String.newLine
                String.newLine
                memoryVarsInfo
            }
        }.toString()
        
        if let parseErr = err as? ParsingError {
            let pInfo = parseErr.pInfo
            let msg = """
                      🐞🐞 ERROR WHILE PARSING 🐞🐞
                       \(pInfo.identifier) [\(pInfo.lineNo)] \(parseErr.info)
                      
                      \(extraInfo)
                      
                      """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let parseErr = err as? Model_ParsingError {
            let pInfo = parseErr.pInfo
            let msg = """
                      🐞🐞 ERROR WHILE PARSING MODELS 🐞🐞
                       \(pInfo.identifier) [\(pInfo.lineNo)] \(parseErr.info)
                      
                      \(extraInfo)
                      
                      """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let evalErr = err as? EvaluationError {
            let pInfo = evalErr.pInfo
            
            var info = ""
            if case let .invalidAppState(string, _) = evalErr {
                info = string
            } else if case let .invalidInput(string, _) = evalErr {
                info = string
            } else {
                info = evalErr.info
            }
            let msg = """
                  🐞🐞 ERROR DURING EVAL 🐞🐞
                   \(pInfo.identifier) [\(pInfo.lineNo)] \(info)
                  
                  \(extraInfo)
                  
                  """
            print(msg)
            //print(Thread.callStackSymbols)
        } else if let err = err as? ErrorWithMessageAndParsedInfo {
            let msg = """
                  🐞🐞 UNKNOWN ERROR 🐞🐞
                   \(err.info)
                  
                  \(extraInfo)
                  
                  """
            print(msg)
            //print(Thread.callStackSymbols)
        } else {
            print("❌❌ UNKNOWN INTERNAL ERROR ❌❌")
            print(err)
        }
        
    }
    
    fileprivate func dumpMemory(context: Context) async -> String{
        let variables = await context.variables.snapshot()
        
        return StringTemplate {
            for va in variables {
                String.newLine
                let value = va.value
                
                if let arr = value as? [Any] {
                    "\(va.key) =" + .newLine
                    for item in arr {
                        "| \(item)"
                    }
                } else if let unwrappedValue = deepUnwrap(value) {  // Cast to Optional<Any>
                    "\(va.key) = \(unwrappedValue)"
                } else {
                    "\(va.key) = null"
                }
            }
        }.toString()
    }
}
