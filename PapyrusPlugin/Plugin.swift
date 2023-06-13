#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIMacro.self,
        DecoratorMacro.self,
    ]
}
#endif
