# ModelHike



# Architecture Design Records
- Swift-UI compatible syntax is used for two reasons:
    1. iOS Devs can start using this Framework, by creating SwiftUI views and then, convert the view into a Webpage, by just changing the 'import SwiftUI' to 'import HtmlTail' 
    2. With advent of GenAI, as LLMS excel in generating code for known frameworks, we are piggybacking on their ability to generate SwiftUI code, to make them generate code for this HtmlTail framwork
