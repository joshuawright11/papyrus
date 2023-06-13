import SwiftSyntax
import SwiftSyntaxMacros

// TODO: Mocking (@Mock)
// DONE 1. Generate `mock\(function) { param -> Res }` functions for each function.
// DONE 2. Add a separate `TodosMock` class.
// DONE 3. Default each function to throw an error (or custom response; inject closure instead of provider).
// DONE 4. Check to see if function has been mocked before hand.

struct MockMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `protocol` = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        return [
            `protocol`.createMock()
        ]
        .map { DeclSyntax(stringLiteral: $0) }
    }
}
