import SwiftSyntax
import SwiftSyntaxMacros

// TODO: Mocking (@Mock)
// 1. Generate `mock\(function) { param -> Res }` functions for each function.
// DONE 2. Add a separate `TodosMock` class.
// 3. Default each function to throw an error (or custom response; inject closure instead of provider).
// 4. Check to see if function has been mocked before hand.

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
            `protocol`.createAPI(),
            `protocol`.createMock()
        ]
        .compactMap { $0 }
        .map { DeclSyntax(stringLiteral: $0) }
    }
}
