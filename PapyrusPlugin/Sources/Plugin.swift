#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIMacro.self,
        APIRoutesMacro.self,
        MockMacro.self,
        DecoratorMacro.self,
    ]
}
#endif
