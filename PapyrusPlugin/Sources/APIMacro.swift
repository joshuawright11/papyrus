import SwiftSyntax
import SwiftSyntaxMacros

public struct APIMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try handleError {
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
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init)
    }
}

extension FunctionDeclSyntax {
    fileprivate func apiFunction() throws -> String {
        let (method, path) = try apiMethodAndPath()
        let pathParameters = path.components(separatedBy: "/")
            .filter { $0.hasPrefix(":") }
            .map { String($0.dropFirst()) }
        
        try validateSignature()

        let attributes = parameters.compactMap({ $0.apiAttribute(httpMethod: method, pathParameters: pathParameters) })
        try validateAttributes(attributes)

        let decl = parameters.isEmpty && apiAttributes.count <= 1 ? "let" : "var"
        var buildRequest = """
            \(decl) req = builder(method: "\(method)", path: \(path))
            """

        for statement in apiAttributes.compactMap({ $0.apiBuilderStatement() }) {
            buildRequest.append("\n" + statement)
        }

        for statement in try parameters.compactMap({ try $0.apiBuilderStatement(httpMethod: method, pathParameters: pathParameters) }) {
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

    private func validateAttributes(_ apiAttributes: [APIAttribute]) throws {
        var bodies = 0, fields = 0
        for attribute in apiAttributes {
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
                    let expression = element.type == "Response" ? "res" : "try res.decode(\(element.type).self, using: req.responseDecoder)"
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
            return "try res.decode(\(string).self, using: req.responseDecoder)"
        default:
            return nil
        }
    }

    private var apiAttributes: [APIAttribute] {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init)
    }
}

extension FunctionParameterSyntax {
    fileprivate func apiBuilderStatement(httpMethod: String, pathParameters: [String]) throws -> String? {
        guard !isClosure else {
            return nil
        }

        return apiAttribute(httpMethod: httpMethod, pathParameters: pathParameters)
            .apiBuilderStatement(input: variableName)
    }

    func apiAttribute(httpMethod: String, pathParameters: [String]) -> APIAttribute {
        if let explicitAPIAttribute {
            // If user specifies the attribute, use that.
            return explicitAPIAttribute
        } else if pathParameters.contains(variableName) {
            // If matches a path param, roll with that
            return .path(key: nil)
        } else if ["GET", "HEAD", "DELETE"].contains(httpMethod) {
            // If method is GET, HEAD, DELETE
            return .query(key: nil)
        } else {
            // Else field
            return .field(key: nil)
        }
    }

    fileprivate var explicitAPIAttribute: APIAttribute? {
        switch type.as(IdentifierTypeSyntax.self)?.name.text {
        case "Path":
            return .path(key: nil)
        case "Body":
            return .body
        case "Header":
            return .header(key: nil)
        case "Field":
            return .field(key: nil)
        case "Query":
            return .query(key: nil)
        default:
            return nil
        }
    }

    private var isClosure: Bool {
        type.as(AttributedTypeSyntax.self)?.baseType.is(FunctionTypeSyntax.self) ?? false
    }
}
