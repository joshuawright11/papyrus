import SwiftSyntax
import SwiftSyntaxMacros

struct APIMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `protocol` = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        return [
            `protocol`.createAPI(),
        ]
        .map { DeclSyntax(stringLiteral: $0) }
    }
}
