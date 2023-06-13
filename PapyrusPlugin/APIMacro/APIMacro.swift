import SwiftSyntax
import SwiftSyntaxMacros

// TODO: Return a tuple with the Raw Response
// TODO: Mocking (@Mock)

// TODO: Finish provider
// TODO: Alamofire
// TODO: Interceptor

// TODO: Tests
// TODO: Custom compiler errors
// TODO: Final cleanup
// TODO: README.md

// TODO: Launch Twitter, HN, Swift Forums, r/swift, r/iOSProgramming Tuesday morning 9am

// TODO: Multipart

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
            DeclSyntax(stringLiteral: `protocol`.createAPI())
        ]
    }
}
