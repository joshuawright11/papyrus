import SwiftSyntax

struct API {
    struct Endpoint {
        /// Modifiers to be applied to this endpoint. These take precedence
        /// over modifiers at the API scope.
        let modifiers: [EndpointModifier]
        let method: String
        let path: String
        let pathParameters: [String]
        /// The name of the function defining this endpoint.
        let name: String
        let parameters: [EndpointParameter]
        let responseType: String?
    }

    /// The name of the protocol defining the API.
    let name: String
    /// The access level of the API (public, internal, etc).
    let access: String?
    /// Modifiers to be applied to every endpoint of this API.
    let modifiers: [EndpointModifier]
    let endpoints: [Endpoint]
}

extension API {
    static func parse(_ decl: some DeclSyntaxProtocol) throws -> API {
        guard let proto = decl.as(ProtocolDeclSyntax.self) else {
            throw PapyrusPluginError("APIs must be protocols for now")
        }
        
        return API(
            name: proto.protocolName,
            access: proto.access,
            modifiers: proto.protocolAttributes.compactMap { EndpointModifier($0) },
            endpoints: try proto.functions.map( { try parse($0) })
        )
    }

    private static func parse(_ function: FunctionDeclSyntax) throws -> API.Endpoint {
        guard function.effects == ["async", "throws"] else {
            throw PapyrusPluginError("Function signature must have `async throws`.")
        }

        let (method, path, pathParameters) = try parseMethodAndPath(function)
        return API.Endpoint(
            modifiers: function.functionAttributes.compactMap { EndpointModifier($0) },
            method: method,
            path: path,
            pathParameters: pathParameters,
            name: function.functionName,
            parameters: try function.parameters.compactMap {
                EndpointParameter($0, httpMethod: method, pathParameters: pathParameters)
            }.validated(),
            responseType: function.returnType
        )
    }

    private static func parseMethodAndPath(
        _ function: FunctionDeclSyntax
    ) throws -> (method: String, path: String, pathParameters: [String]) {
        var method, path: String?
        for attribute in function.functionAttributes {
            if case let .argumentList(list) = attribute.arguments {
                let name = attribute.attributeName.trimmedDescription
                switch name {
                case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
                    method = name
                    path = list.first?.expression.description.withoutQuotes
                case "HTTP":
                    method = list.first?.expression.description.withoutQuotes
                    path = list.dropFirst().first?.expression.description.withoutQuotes
                default:
                    continue
                }
            }
        }

        guard let method, let path else {
            throw PapyrusPluginError("No method or path!")
        }

        return (method, path, path.papyrusPathParameters)
    }
}

extension API.Endpoint {
    var functionSignature: String {
        let parameters = parameters.map {
            let name = [$0.label, $0.name]
                .compactMap { $0 }
                .joined(separator: " ")
            return "\(name): \($0.type)"
        }

        let returnType = responseType.map { " -> \($0)" } ?? ""
        return parameters.joined(separator: ", ").inParentheses + " async throws" + returnType
    }
}

extension [EndpointParameter] {
    fileprivate func validated() throws -> [EndpointParameter] {
        let bodies = filter { $0.kind == .body }
        let fields = filter { $0.kind == .field }

        guard fields.count == 0 || bodies.count == 0 else {
            throw PapyrusPluginError("Can't have Body and Field!")
        }

        guard bodies.count <= 1 else {
            throw PapyrusPluginError("Can only have one Body!")
        }

        return self
    }
}
