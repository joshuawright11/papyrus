#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MyPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        APIMacro.self,
        RoutesMacro.self,
        MockMacro.self,
        DecoratorMacro.self,
    ]
}
#endif
