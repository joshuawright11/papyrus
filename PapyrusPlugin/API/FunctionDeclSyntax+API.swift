import Foundation
import SwiftSyntax

extension FunctionDeclSyntax {
    enum ReturnType {
        case tuple([(label: String?, type: String)])
        case type(String)
    }

    var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
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

    private var returnStatements: [String] {
        switch returnType {
        case .tuple(let array):
            let elements = array.map { element in
                let decodeElement = element.type == "Response" ? "res" : "try req.contentConverter.decode(\(element.type).self, from: res.body)"
                return [
                    element.label,
                    decodeElement
                ]
                .compactMap { $0 }
                .joined(separator: ": ")
            }
            return [
                """
                return (
                    \(elements.joined(separator: ",\n"))
                )
                """
            ]
        case .type(let string):
            return [
                "return try req.contentConverter.decode(\(string).self, from: res.body)"
            ]
        case nil:
            return []
        }
    }

    var mockFunctions: [String] {
        [mockFunction, mockerFunction]
    }

    private var mockFunction: String {
        guard isAsync, isThrows else {
            return "Not async throws!"
        }

        let input = parameters.map { $0.secondName ?? $0.firstName }.map(\.text).joined(separator: ", ")
        return """
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
            self.mocks["\(name)"] = result
        }
        """
    }

    func apiFunction(protocolAttributes: [Attribute]) -> String {
        guard isAsync, isThrows else {
            return "Not async throws!"
        }

        var topLevelStatements: [String] = []
        var method: String?
        var path: String?
        for attribute in papyrusAttributes {
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
        let decl = parameters.isEmpty && papyrusAttributes.count <= 1 ? "let" : "var"
        let newRequestFunction = protocolAttributes.isEmpty ? "RequestBuilder" : "newRequest"
        let requestStatement = """
            \(decl) req = \(newRequestFunction)(method: "\(method)", path: \(path))
            """

        // Request Construction
        let buildStatements = parameters.compactMap(\.apiBuilderStatement)

        // Get Response
        let responseAssignment = returnType == nil ? "" : "let res = "
        let responseStatement = "\(responseAssignment)try await provider.request(req)"

        let lines: [String?] = [
            "\(concreteSignature) {",
            requestStatement,
            topLevelStatements.joined(separator: "\n"),
            buildStatements.joined(separator: "\n"),
            responseStatement,
            returnStatements.joined(separator: "\n"),
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
        let closureReturn = returnClause.isEmpty ? " -> Void" : returnClause
        return "(\(parameters)) async throws\(closureReturn)"
    }

    private var concreteSignature: String {
        let nameString = identifier
        let parametersString = parameters.map(\.signatureString).joined(separator: ", ")
        return """
            func \(nameString)(\(parametersString)) async throws\(returnClause)
            """
    }

    private var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    private var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
}
