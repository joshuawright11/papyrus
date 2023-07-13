import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct DecoratorMacro: PeerMacro {
    static func expansion(of _: AttributeSyntax,
                          providingPeersOf _: some DeclSyntaxProtocol,
                          in _: some MacroExpansionContext) throws -> [DeclSyntax]
    {
//        let messageID = MessageID(domain: "test", id: "papyrus")
//        let message = MyDiagnostic(message: "Testing Peer!", diagnosticID: messageID, severity: .warning)
//        let diagnostic = Diagnostic(node: Syntax(node), message: message)
//        context.diagnose(diagnostic)
        // TODO: Add some compiler safety to ensure certain attributes can't be on certain members.
        return []
    }
}

struct MyDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}
