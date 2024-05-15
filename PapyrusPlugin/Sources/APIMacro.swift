import Foundation
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

            let name = node.firstArgument ?? "\(type.typeName)\(node.attributeName)"
            return try type.createAPI(named: name)
        }
    }
}

extension ProtocolDeclSyntax {
    func createAPI(named apiName: String) throws -> String {
        """
        \(access)struct \(apiName): \(typeName) {
            private let provider: PapyrusCore.Provider

            \(access)init(provider: PapyrusCore.Provider) {
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
        try validateSignature()

        func pathParameter(from component: String) -> String? {
            if component.hasPrefix(":") {
                return String(component.dropFirst())
            } else if component.hasPrefix("{") && component.hasSuffix("}") {
                return String(component.dropFirst().dropLast())
            } else {
                return nil
            }
        }

        let pathComponents = path.components(separatedBy: "/")
        let pathParameters = pathComponents.compactMap(pathParameter)

        let attributes = parameters.compactMap({ $0.apiAttribute(httpMethod: method, pathParameters: pathParameters) })
        try validateAttributes(attributes)

		let declaration = pathParameters.isEmpty ? "let" : "var"
        var buildRequest = """
            \(declaration) pathComponents: [String] = [\(
                pathComponents
                    .filter { !$0.isEmpty }
                    .map { "\"\($0)\"" }
                    .joined(separator: ", "))]
            """

        for (index, component) in pathComponents.dropFirst().enumerated() {
            if let parameter = pathParameter(from: component) {
                buildRequest += """
                    if \(parameter) as Any? == nil {
                        pathComponents.remove(at: \(index))
                    }
                    """
            }
        }

        buildRequest += """
           let path = pathComponents.joined(separator: "/")
           var req = builder(method: \"\(method)\", path: path)
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
                    provider.request(&req) { res in
                    \(callbackName)(res)
                    }
                    """
            } else {
                return """
                    provider.request(&req) { res in
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
            case .type("Void"), .none:
                return "try await provider.request(&req).validate()"
            case .type where returnResponseOnly:
                return "return try await provider.request(&req)"
            case .type, .tuple:
                guard let resultExpression else {
                    throw PapyrusPluginError("Missing result expression!")
                }

                return """
                    let res = try await provider.request(&req)
                    try res.validate()
                    return \(resultExpression)
                    """
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
        } else if pathParameters.contains(KeyMapping.snakeCase.encode(variableName)) {
            // If matches snake cased param, add that
            return .path(key: KeyMapping.snakeCase.encode(variableName))
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

/// Represents the mapping between your type's property names and
/// their corresponding request field key.
private enum KeyMapping {
    /// Convert property names from camelCase to snake_case for field keys.
    ///
    /// e.g. `someGreatString` -> `some_great_string`
    case snakeCase

    /// Encode String from camelCase to this KeyMapping strategy.
    func encode(_ string: String) -> String {
        switch self {
        case .snakeCase:
            return string.camelCaseToSnakeCase()
        }
    }
}

extension String {
    /// Map camelCase to snake_case. Assumes `self` is already in
    /// camelCase. Copied from `Foundation`.
    ///
    /// - Returns: The snake_cased version of `self`.
    fileprivate func camelCaseToSnakeCase() -> String {
        guard !self.isEmpty else { return self }

        var words : [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = self.startIndex
        var searchRange = self.index(after: wordStart)..<self.endIndex

        // Find next uppercase character
        while let upperCaseRange = self.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = self.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }

            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = self.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = self.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }

        words.append(wordStart..<searchRange.upperBound)
        return words
            .map { range in
                self[range].lowercased()
            }
            .joined(separator: "_")
    }
}
