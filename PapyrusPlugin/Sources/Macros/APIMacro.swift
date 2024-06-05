import SwiftSyntax
import SwiftSyntaxMacros

public struct APIMacro: PeerMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try [
            API.parse(declaration)
                .liveImplementation(suffix: attribute.name)
                .declSyntax()
        ]
    }
}

extension API {
    func liveImplementation(suffix: String) throws -> Declaration {
        Declaration("struct \(name)\(suffix): \(name)") {

            // 0. provider reference & init

            "private let provider: Papyrus.Provider"

            Declaration("init(provider: Papyrus.Provider)") {
                "self.provider = provider"
            }
            .access(access)

            // 1. live endpoint implementations

            for endpoint in endpoints {
                endpoint.liveFunction().access(access)
            }

            // 2. builder used by all live endpoint functions

            Declaration("func builder(method: String, path: String) -> Papyrus.RequestBuilder") {
                if attributes.isEmpty {
                    "provider.newBuilder(method: method, path: path)"
                } else {
                    "var req = provider.newBuilder(method: method, path: path)"
                    
                    for modifier in attributes {
                        modifier.builderStatement()
                    }

                    "return req"
                }
            }
            .private()
        }
        .access(access)
    }
}

extension API.Endpoint {
    func liveFunction() -> Declaration {
        Declaration("func \(name)\(functionSignature)") {
            
            // 0. create a request builder

            "var req = builder(method: \(method.inQuotes), path: \(path.inQuotes))"

            // 1. add function scope attributes

            for attribute in attributes {
                attribute.builderStatement()
            }

            // 2. add parameters

            for parameter in parameters {
                parameter.builderStatement()
            }

            // 3. handle the response and return

            switch responseType {
            case .none, "Void":
                "try await provider.request(&req).validate()"
            case "Response":
                "return try await provider.request(&req)"
            case .some(let type):
                "let res = try await provider.request(&req)"
                "try res.validate()"
                "return try res.decode(\(type).self, using: req.responseBodyDecoder)"
            }
        }
    }
}

extension EndpointParameter {
    fileprivate func builderStatement() -> String {
        switch kind {
        case .body:
            "req.setBody(\(name))"
        case .query:
            "req.addQuery(\(name.inQuotes), value: \(name))"
        case .header:
            "req.addHeader(\(name.inQuotes), value: \(name), convertToHeaderCase: true)"
        case .path:
            "req.addParameter(\(name.inQuotes), value: \(name))"
        case .field:
            "req.addField(\(name.inQuotes), value: \(name))"
        }
    }
}

extension EndpointAttribute {
    fileprivate func builderStatement() -> String {
        switch self {
        case .json(let encoder, let decoder):
            """
            req.requestBodyEncoder = .json(\(encoder))
            req.responseBodyDecoder = .json(\(decoder))
            """
        case .urlForm(let encoder):
            "req.requestBodyEncoder = .urlForm(\(encoder))"
        case .multipart(let encoder):
            "req.requestBodyEncoder = .multipart(\(encoder))"
        case .converter(let encoder, let decoder):
            """
            req.requestBodyEncoder = \(encoder)
            req.responseBodyDecoder = \(decoder)
            """
        case .headers(let value):
            "req.addHeaders(\(value))"
        case .keyMapping(let value):
            "req.keyMapping = \(value)"
        case .authorization(value: let value):
            "req.addAuthorization(\(value))"
        }
    }
}
