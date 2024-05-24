import SwiftSyntax
import SwiftSyntaxMacros

public struct RoutesMacro: PeerMacro, ExtensionMacro {

    // MARK: PeerMacro

    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try [
            API.parse(declaration)
                .registry()
                .declSyntax(),
        ]
    }

    // MARK: ExensionMacro

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        try [
            API.parse(declaration)
                .routesExtension()
                .extensionDeclSyntax()
        ]
    }
}

extension API {
    func registry() -> Declaration {
        Declaration("enum \(name)Routes") {
            Declaration("static func register(api: \(name), router: PapyrusRouter)") {
                for endpoint in endpoints {
                    endpoint.registerStatement()
                }
            }
        }
        .private()
    }

    func routesExtension() -> Declaration {
        Declaration("extension \(name) where Self: PapyrusRouter") {
            Declaration("func useAPI(_ api: (any \(name)).Type)") {
                "\(name)Routes.register(api: self, router: self)"
            }
        }
        .access(access)
    }
}

extension API.Endpoint {
    func registerStatement() -> Declaration {
        Declaration("router.register(method: \(method.inQuotes), path: \(path.inQuotes))", "req") {
            for parameter in parameters {
                parameter.parserStatement(path: path)
            }

            let fields = parameters.filter { $0.kind == .field }
            if !fields.isEmpty {
                Declaration("struct Body: Decodable") {
                    for field in fields {
                        "let \(field.name): \(field.type)"
                    }
                }

                "let body = try req.getBody(Body.self)"
            }

            let arguments = parameters.map(\.argumentString).joined(separator: ", ").inParentheses
            let status = method == "POST" ? 201 : 200
            if responseType == "Void" || responseType == nil {
                "try await api.\(name)\(arguments)"
                "return RouterResponse(\(status))"
            } else {
                "let value = try await api.\(name)\(arguments)"
                "let data = try JSONEncoder().encode(value)"
                "return RouterResponse(\(status), body: data)"
            }
        }
    }
}

extension EndpointParameter {
    fileprivate var argumentString: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        let label = argumentLabel.map { "\($0): " } ?? ""
        let prefix = kind == .field ? "body." : ""
        return label + prefix + name
    }
}

extension EndpointParameter {
    fileprivate func parserStatement(path: String) -> String? {
        switch kind {
        case .body:
            "let \(name): \(type) = try req.getBody(\(type).self)"
        case .query:
            "let \(name): \(type) = try req.getQuery(\(name.inQuotes))"
        case .header:
            "let \(name): \(type) = try req.getHeader(\(name.inQuotes))"
        case .path:
            "let \(name): \(type) = try req.getParameter(\(name.inQuotes), path: \(path.inQuotes))"
        case .field:
            nil
        }
    }
}
