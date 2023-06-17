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
            `protocol`.createAPI(node.argString),
        ]
        .map { DeclSyntax(stringLiteral: $0) }
    }
}

extension AttributeSyntax {
    var argString: String? {
        if case let .argumentList(list) = argument {
            return list.first?.expression.description.withoutQuotes
        }

        return nil
    }
}
