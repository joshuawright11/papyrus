import SwiftSyntax
import SwiftSyntaxMacros

public struct APIRoutesMacro: PeerMacro, ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax, 
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let type = declaration.as(ProtocolDeclSyntax.self) else {
            throw PapyrusPluginError("@APIRoutes can only be applied to protocols.")
        }

        return try [
            ExtensionDeclSyntax(
                .init(stringLiteral: type.createRoutesExtension())
            )
        ]
    }

    public static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
//        try handleError {
//            guard let type = declaration.as(ProtocolDeclSyntax.self) else {
//                throw PapyrusPluginError("@APIRoutes can only be applied to protocols.")
//            }
//
//            let name = node.firstArgument ?? "\(type.typeName)Live"
//            return try [
//                type.createAPI(named: name),
//                type.createRegistry(),
//            ]
//        }
        []
    }
}

extension ProtocolDeclSyntax {
    func createRoutesExtension() throws -> String {
        """
        \(access)extension \(protocolName) where Self: PapyrusRouter {
            func useAPI(_ api: (any \(protocolName)).Type) {
                \(protocolName)Registry.register(api: self, router: self)
            }
        }
        """
    }

    func createRegistry() throws -> String {
        """
        private enum \(protocolName)Registry {
            static func register(api: \(protocolName), router: PapyrusRouter) {
                // TODO
            }
        }
        """
    }
}
