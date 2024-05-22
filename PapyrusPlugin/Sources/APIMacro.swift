import SwiftSyntax
import SwiftSyntaxMacros

public struct APIMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            throw PapyrusPluginError("@API can only be applied to protocols.")
        }

        return [
            try proto
                .liveService(named: "\(proto.protocolName)\(node.attributeName)")
                .declSyntax()
        ]
    }
}

extension ProtocolDeclSyntax {
    func liveService(named name: String) throws -> Declaration {
        try Declaration("\(access)struct \(name): \(protocolName)") {

            // 0. provider reference & init

            "private let provider: PapyrusCore.Provider"

            Declaration("init(provider: PapyrusCore.Provider)") {
                "self.provider = provider"
            }

            // 1. live endpoint implementations

            for function in functions {
                try function.liveEndpointFunction(access: access)
            }

            // 2. builder used by all live endpoint functions

            Declaration("private func builder(method: String, path: String) -> RequestBuilder") {
                let modifiers = protocolAttributes.compactMap { EndpointModifier($0) }
                if modifiers.isEmpty {
                    "provider.newBuilder(method: method, path: path)"
                } else {
                    "var req = provider.newBuilder(method: method, path: path)"

                    modifiers.compactMap { $0.builderStatement() }

                    "return req"
                }
            }
        }
    }
}

extension FunctionDeclSyntax {
    fileprivate func liveEndpointFunction(access: String) throws -> Declaration {
        guard effects == ["async", "throws"] else {
            throw PapyrusPluginError("Function signature must have `async throws`.")
        }

        return try Declaration("\(access)func \(functionName)\(signature)") {
            let modifiers = functionAttributes.compactMap { EndpointModifier($0) }
            let (method, path, pathParameters) = try modifiers.parseMethodAndPath()

            // 0. create a request builder

            "var req = builder(method: \(method.inQuotes), path: \(path.inQuotes))"

            // 1. add function scope modifiers

            modifiers
                .compactMap { $0.builderStatement() }

            // 2. add parameters

            try parameters
                .map { EndpointParameter($0, httpMethod: method, pathParameters: pathParameters) }
                .validated()
                .map { $0.builderStatement() }

            // 3. handle the response and return

            try responseStatement()
        }
    }

    private func responseStatement() throws -> String {
        let requestAndValidate = """
            let res = try await provider.request(&req)
            try res.validate()
            """
        switch returnType {
        case .type("Void"), .none:
            return "try await provider.request(&req).validate()"
        case .type where returnResponseOnly:
            return "return try await provider.request(&req)"
        case .type(let type):
            return """
                \(requestAndValidate)
                return try res.decode(\(type).self, using: req.responseDecoder)
                """
        case .tuple(let types):
            let values = types.map { label, type in
                let label = label.map { "\($0): " } ?? ""
                if type == "Response" {
                    return "\(label)res"
                } else {
                    return "\(label)try res.decode(\(type).self, using: req.responseDecoder)"
                }
            }

            return """
                \(requestAndValidate)
                return (
                    \(values.joined(separator: ",\n"))
                )
                """
        }
    }
}
