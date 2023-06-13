import SwiftSyntax
import SwiftSyntaxMacros

// TODO: Interceptor
// TODO: Alamofire or Generic?
// TODO: Finish provider

// TODO: Tests
// TODO: Custom compiler errors
// TODO: Final cleanup
// TODO: README.md

// TODO: Launch Twitter, HN, Swift Forums, r/swift, r/iOSProgramming Tuesday morning 9am

// TODO: Multipart
// TODO: Provider Requests on Server
// TODO: Custom RequestEncodable Protocol (for functions with lots of arguments)

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
            `protocol`.createAPI()
        ]
        .map { DeclSyntax(stringLiteral: $0) }
    }
}
