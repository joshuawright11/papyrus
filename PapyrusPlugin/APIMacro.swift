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

            let name = node.firstArgument ?? "\(type.typeName)API"
            return try type.createAPI(named: name)
        }
    }
}

extension ProtocolDeclSyntax {
    func createAPI(named apiName: String) throws -> String {
        """
        \(access)struct \(apiName): \(typeName) {
            private let provider: Provider

            \(access)init(provider: Provider) {
                self.provider = provider
            }

        \(try generateAPIFunctions())
        }
        """
    }

    private func generateAPIFunctions() throws -> String {
        var functions = try functions
            .map { try $0.apiFunction() }
            .map { access + $0 }
        functions.append(newRequestFunction)
        return functions.joined(separator: "\n\n")
    }

    private var newRequestFunction: String {
        let globalBuilderStatements = apiAttributes.compactMap { $0.apiBuilderStatement() }
        let content = globalBuilderStatements.isEmpty
            ? """
              provider.newBuilder(method: method, path: path)
              """
            : """
              var req = provider.newBuilder(method: method, path: path)
              \(globalBuilderStatements.joined(separator: "\n"))
              return req
              """
        return """
            private func builder(method: String, path: String) -> RequestBuilder {
            \(content)
            }
            """
    }

    private var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }
}

extension FunctionDeclSyntax {
    fileprivate func apiFunction() throws -> String {
        let (method, path) = try apiMethodAndPath()
        try validateSignature()
        try validateBody()

        let decl = parameters.isEmpty && apiAttributes.count <= 1 ? "let" : "var"
        var buildRequest = """
            \(decl) req = builder(method: "\(method)", path: \(path))
            """

        for statement in apiAttributes.compactMap({ $0.apiBuilderStatement() }) {
            buildRequest.append("\n" + statement)
        }

        for statement in try parameters.compactMap({ try $0.apiBuilderStatement() }) {
            buildRequest.append("\n" + statement)
        }

        return """
            func \(functionName)\(signature) {
            \(buildRequest)
            \(try handleResponse())
            }
            """
    }

    private func handleResponse() throws -> String {
        switch style {
        case .completionHandler:
            guard let callbackName else {
                throw PapyrusPluginError("No callback found!")
            }

            if returnResponseOnly {
                return """
                    provider.request(req) { res in
                    \(callbackName)(res)
                    }
                    """
            } else {
                return """
                    provider.request(req) { res in
                        do {
                            try res.validate()
                            \(resultExpression.map { "let res = \($0)" } ?? "")
                            \(callbackName)(.success(res))
                        } catch {
                            \(callbackName)(.failure(error))
                        }
                    }
                    """
            }
        case .concurrency:
            switch responseType {
            case .type where returnResponseOnly:
                return "return try await provider.request(req)"
            case .type, .tuple:
                guard let resultExpression else {
                    throw PapyrusPluginError("Missing result expression!")
                }

                return """
                    let res = try await provider.request(req)
                    return \(resultExpression)
                    """
            case .none:
                return "try await provider.request(req).validate()"
            }
        }
    }

    private func apiMethodAndPath() throws -> (method: String, path: String) {
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

    private func validateBody() throws {
        var bodies = 0, fields = 0
        for attribute in parameters.flatMap(\.apiAttributes) {
            switch attribute {
            case .body:
                bodies += 1
            case .field:
                fields += 1
            default:
                continue
            }
        }

        guard fields == 0 || bodies == 0 else {
            throw PapyrusPluginError("Can't have @Body and @Field!")
        }

        guard bodies <= 1 else {
            throw PapyrusPluginError("Can only have one @Body!")
        }
    }

    private var resultExpression: String? {
        guard !returnResponseOnly else {
            return nil
        }

        switch responseType {
        case .tuple(let array):
            let elements = array
                .map { element in
                    let expression = element.type == "Response" ? "res" : "try req.responseDecoder.decode(\(element.type).self, from: res)"
                    return [element.label, expression]
                        .compactMap { $0 }
                        .joined(separator: ": ")
                }
            return """
                (
                    \(elements.joined(separator: ",\n"))
                )
                """
        case .type(let string):
            return "try req.responseDecoder.decode(\(string).self, from: res)"
        default:
            return nil
        }
    }

    private var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }
}

extension FunctionParameterSyntax {
    fileprivate func apiBuilderStatement() throws -> String? {
        guard !isClosure else {
            return nil
        }

        var parameterAttribute: APIAttribute? = nil
        for attribute in apiAttributes {
            switch attribute {
            case .body, .query, .header, .path, .field:
                guard parameterAttribute == nil else {
                    throw PapyrusPluginError("Only one attribute is allowed per parameter!")
                }

                parameterAttribute = attribute
            default:
                break
            }
        }

        let attribute = parameterAttribute ?? .field(key: nil)
        return attribute.apiBuilderStatement(input: variableName)
    }

    fileprivate var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }

    private var isClosure: Bool {
        type.as(AttributedTypeSyntax.self)?.baseType.is(FunctionTypeSyntax.self) ?? false
    }
}
