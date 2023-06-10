import SwiftSyntax
import SwiftSyntaxMacros

struct GetMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure it's a function.
//        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
//            // TODO: Show an error.
//            return []
//        }

        // Get the path string.
        let args = node.argument
        print("GOT ARGS: \(args)")
        return [
            "typealias Foo = String"
        ]
    }
}

struct HeaderMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
