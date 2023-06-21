import SwiftSyntax
import SwiftSyntaxMacros

struct APIMacro: PeerMacro {
    static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        handleError {
            guard let type = declaration.as(ProtocolDeclSyntax.self) else {
                throw PapyrusPluginError("@API can only be applied to protocols.")
            }

            return try type.createAPI(named: node.firstArgument)
        }
    }
}

extension ProtocolDeclSyntax {
    func createAPI(named customName: String?) throws -> String {
        let customName = customName.map { "struct \($0)" }
        let name = customName ?? "struct \(identifier.trimmed)API"
        return [
            """
            \(access)\(name): \(identifier.trimmed) {
            private let provider: Provider

            \(access)init(provider: Provider) {
                self.provider = provider
            }

            """,
            (try createApiFunctions() + [newRequestFunction])
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n"),
            "}"
        ]
        .joined(separator: "\n")
    }

    private func createApiFunctions() throws -> [String] {
        try functions
            .map { try $0.apiFunction(protocolAttributes: apiAttributes) }
            .map { access + $0 }
    }

    private var newRequestFunction: String {
        guard !globalStatements.isEmpty else {
            return ""
        }

        return """
        private func newBuilder(method: String, path: String) -> RequestBuilder {
            var req = provider.newBuilder(method: method, path: path)
            \(globalStatements.joined(separator: "\n") )
            return req
        }
        """
    }

    private var globalStatements: [String] {
        apiAttributes.compactMap { $0.requestStatement(input: nil) }
    }

    private var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }
}

extension FunctionDeclSyntax {
    func apiMethodAndPath() throws -> (method: String, path: String) {
        var method, path: String?
        for attribute in apiAttributes {
            switch attribute {
            case let .http(_method, _path):
                guard method == nil, path == nil else {
                    throw PapyrusPluginError("Only one method per function!")
                }

                (method, path) = (_method, _path)
            default:
                continue
            }
        }

        guard let method, let path else {
            throw PapyrusPluginError("No method or path!")
        }

        return (method, path)
    }

    func apiFunction(protocolAttributes: [APIAttribute]) throws -> String {
        let (method, path) = try apiMethodAndPath()
        try validateSignature()
        try validateBody()

        var topLevelStatements: [String] = []
        for attribute in apiAttributes {
            switch attribute {
            case .http:
                continue
            default:
                if let statement = attribute.requestStatement(input: nil) {
                    topLevelStatements.append(statement)
                }
            }
        }

        // Request Initialization
        let decl = parameters.isEmpty && apiAttributes.count <= 1 ? "let" : "var"
        let newRequestFunction = protocolAttributes.isEmpty ? "provider.newBuilder" : "newBuilder"
        let requestStatement = """
            \(decl) req = \(newRequestFunction)(method: "\(method)", path: \(path))
            """

        // Request Construction
        let buildStatements = parameters.compactMap(\.apiBuilderStatement)

        // Get Response
        let responseAssignment =
            switch responseType {
            case .tuple:
                "let res = "
            case .type:
                if returnsResponse { "return " } else { "let res = " }
            case .none:
                ""
            }

        let validation = responseType == nil ? ".validate()" : ""
        let responseStatement = callbackName.map { callback in
            let closureContent = returnsResponse
                ? "\(callback)(res)"
                : """
                    do {
                        try res.validate()
                        \(returnExpression.map { "let res = \($0)" } ?? "")
                        \(callback)(.success(res))
                    }
                    catch {
                        \(callback)(.failure(error))
                    }
                    """
            return """
            provider.request(req) { res in
                \(closureContent)
            }
            """
        }
        ?? """
        \(responseAssignment)try await provider.request(req)\(validation)
        """

        let _return: String? =
            switch style {
            case .concurrency:
                returnExpression.map { "return \($0)" }
            case .completionHandler:
                nil
            }

        let lines: [String?] = [
            "func \(signatureString) {",
            requestStatement,
            topLevelStatements.joined(separator: "\n"),
            buildStatements.joined(separator: "\n"),
            responseStatement,
            _return,
            "}"
        ]

        return lines
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }

    private func validateBody() throws {
        var hasBody = false
        var hasField = false
        for parameter in parameters {
            for attribute in parameter.apiAttributes {
                switch attribute {
                case .body:
                    guard !hasBody else {
                        throw PapyrusPluginError("Can only have one @Body!")
                    }

                    hasBody = true
                case .field:
                    hasField = true
                default:
                    continue
                }
            }
        }

        guard !hasField || !hasBody else {
            throw PapyrusPluginError("Can't have @Body and @Field!")
        }
    }
}

extension FunctionParameterSyntax {
    var apiBuilderStatement: String? {
        guard !isClosure else {
            return nil
        }

        var parameterAttribute: APIAttribute? = nil
        for attribute in apiAttributes {
            switch attribute {
            case .body, .query, .header, .path, .field:
                guard parameterAttribute == nil else {
                    return "Only one attribute per parameter!"
                }

                parameterAttribute = attribute
            default:
                break
            }
        }

        let attribute = parameterAttribute ?? .field(key: nil)
        return attribute.requestStatement(input: variableName)
    }

    var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }

    private var isClosure: Bool {
        type.as(AttributedTypeSyntax.self)?.baseType.is(FunctionTypeSyntax.self) ?? false
    }
}
