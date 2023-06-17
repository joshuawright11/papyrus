import Foundation
import SwiftSyntax

extension FunctionDeclSyntax {
    enum ReturnType {
        case tuple([(label: String?, type: String)])
        case type(String)
    }

    var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }

    private var returnClause: String {
        guard let returnType else {
            return ""
        }

        let _type: String = {
            switch returnType {
            case .type(let type):
                return type
            case .tuple(let elements):
                let types = elements.map { element in
                    [element.label, element.type]
                        .compactMap { $0 }
                        .joined(separator: ": ")
                }
                
                return "(\(types.joined(separator: ", ")))"
            }
        }()

        return " -> \(_type)"
    }

    private var responseType: ReturnType? {
        if useCallback, let callbackType {
            return .type(callbackType)
        }

        return returnType
    }

    private var returnType: ReturnType? {
        guard let type = signature.output?.returnType else {
            return nil
        }

        if let type = type.as(TupleTypeSyntax.self) {
            return .tuple(type.elements.map { ($0.name?.text, $0.type.trimmedDescription) })
        } else {
            return .type(type.trimmedDescription)
        }
    }

    private var returnExpression: String? {
        switch responseType {
        case .tuple(let array):
            let elements = array.map { element in
                let decodeElement = element.type == "Response" ? "res" : "try req.responseDecoder.decode(\(element.type).self, from: res)"
                return [
                    element.label,
                    decodeElement
                ]
                .compactMap { $0 }
                .joined(separator: ": ")
            }
            return """
                (
                    \(elements.joined(separator: ",\n"))
                )
                """
        case .type(let string) where string != "Response":
            return "try req.responseDecoder.decode(\(string).self, from: res)"
        default:
            return nil
        }
    }

    func mockFunctions(accessLevel: String) -> [String] {
        [mockFunction, mockerFunction]
            .map { accessLevel + $0 }
    }

    private var mockFunction: String {
        guard useConcurrency || useCallback else {
            return "Not async throws or callback!"
        }

        let input = parameters.map { $0.secondName ?? $0.firstName }.map(\.text).joined(separator: ", ")
        return callbackName.map { callback in
            let unimplementedResponse = justResponse ? "ErrorResponse(defaultError)" : ".failure(defaultError)"
            return """
                \(concreteSignature) {
                    guard let mocker = mocks["\(identifier.text)"] as? \(closureSignature) else {
                        \(callback)(\(unimplementedResponse))
                        return
                    }

                    mocker(\(input))
                }
                """

            }
        ??
        """
        \(concreteSignature) {
            guard let mocker = mocks["\(identifier.text)"] as? \(closureSignature) else {
                throw defaultError
            }

            return try await mocker(\(input))
        }
        """
    }

    private var mockerFunction: String {
        let name = identifier.text
        let nameCapitalized = name.prefix(1).capitalized + name.dropFirst()
        return """
        func mock\(nameCapitalized)(result: @escaping \(closureSignature)) {
            mocks["\(name)"] = result
        }
        """
    }

    var justResponse: Bool {
        switch responseType {
        case .type(let string):
            return string == "Response"
        default:
            return false
        }
    }

    func apiFunction(protocolAttributes: [APIAttribute]) -> String {
        guard useConcurrency || useCallback else {
            return "Not async throws or callback!"
        }

        var topLevelStatements: [String] = []
        var method: String?
        var path: String?
        for attribute in apiAttributes {
            switch attribute {
            case let .http(_method, _path):
                guard method == nil, path == nil else {
                    return "Only one method per function!"
                }

                method = _method
                path = _path
            default:
                if let statement = attribute.requestStatement(input: nil) {
                    topLevelStatements.append(statement)
                }
            }
        }

        guard let method, let path else {
            return "No method or path!"
        }

        // Request Parts
        let bodies = parameters.filter(\.isBody)
        let fields = parameters.filter(\.isField)
        guard bodies.count <= 1 else {
            return "Can only have one @Body!"
        }

        guard bodies.isEmpty || fields.isEmpty else {
            return "Can't have @Body and @Field!"
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
        let responseAssignment = switch responseType {
        case .tuple:
            "let res = "
        case .type:
            if justResponse { "return " } else { "let res = " }
        case .none:
            ""
        }

        let validation = responseType == nil ? ".validate()" : ""
        let responseStatement = callbackName.map { callback in
            let closureContent =
            justResponse
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

        let lines: [String?] = [
            "\(concreteSignature) {",
            requestStatement,
            topLevelStatements.joined(separator: "\n"),
            buildStatements.joined(separator: "\n"),
            responseStatement,
            useConcurrency ? returnExpression.map { "return \($0)" } : nil,
            "}"
        ]

        return lines
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private var parameters: [FunctionParameterSyntax] {
        signature
            .input
            .parameterList
            .compactMap { $0.as(FunctionParameterSyntax.self) }
    }

    private var closureSignature: String {
        let parameters = parameters.map(\.closureSignatureString).joined(separator: ", ")
        var closureReturn = " -> Void"
        if useConcurrency {
            closureReturn = "async throws" + (returnClause.isEmpty ? " -> Void" : returnClause)
        }

        return "(\(parameters)) \(closureReturn)"
    }

    private var concreteSignature: String {
        var finalParameterAndReturn = ")"
        if useConcurrency {
            finalParameterAndReturn.append("async throws\(returnClause)")
        }

        let parametersString = parameters.map(\.signatureString).joined(separator: ", ")
        return """
            func \(identifier)(\(parametersString)\(finalParameterAndReturn)
            """
    }

    private var useConcurrency: Bool {
        isAsync && isThrows
    }

    private var callbackName: String? {
        guard let parameter = parameters.last, useCallback else {
            return nil
        }

        return (parameter.secondName ?? parameter.firstName).text
    }

    private var callbackType: String? {
        guard let parameter = parameters.last, returnType == nil else {
            return nil
        }

        let type = parameter.type.trimmedDescription
        if type == "@escaping (Response) -> Void" {
            return "Response"
        } else {
            return type
                .replacingOccurrences(of: "@escaping (Result<", with: "")
                .replacingOccurrences(of: ", Error>) -> Void", with: "")
        }
    }

    private var useCallback: Bool {
        guard let parameter = parameters.last, returnType == nil else {
            return false
        }

        let type = parameter.type.trimmedDescription
        let isResult = type.hasPrefix("@escaping (Result<") && type.hasSuffix("Error>) -> Void")
        let isResponse = type == "@escaping (Response) -> Void"
        return isResult || isResponse
    }

    private var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    private var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
}
