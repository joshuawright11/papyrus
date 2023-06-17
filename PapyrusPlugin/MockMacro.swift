import SwiftSyntax
import SwiftSyntaxMacros

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
            `protocol`.createMock(node.argString)
        ]
        .map { DeclSyntax(stringLiteral: $0) }
    }
}
