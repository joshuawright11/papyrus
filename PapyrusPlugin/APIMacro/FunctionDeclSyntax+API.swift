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

    private var returnStatement: String? {
        switch returnType {
        case .tuple(let array):
            let elements = array.map { element in
                let decodeElement = element.type == "RawResponse" ? "res" : "try res.decodeContent(\(element.type).self)"
                return [
                    element.label,
                    decodeElement
                ]
                .compactMap { $0 }
                .joined(separator: ": ")
            }
            return """
            return (
                \(elements.joined(separator: ",\n"))
            )
            """
        case .type(let string):
            return "return try res.decodeContent(\(string).self)"
        case nil:
            return nil
        }
    }

    func apiFunction(newRequestFunction: String) -> String {
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
                topLevelStatements.append(attribute.requestStatement(input: nil))
            }
        }

        guard let method, let path else {
            return "No method or path!"
        }

        // Inputs
        let parameters = signature.input.parameterList
            .compactMap { $0.as(FunctionParameterSyntax.self) }

        // Request Parts
        let bodies = parameters.filter(\.isBody)
        let fields = parameters.filter(\.isField)
        guard bodies.count <= 1 else {
            return "Can only have one @Body!"
        }

        guard bodies.isEmpty || fields.isEmpty else {
            return "Can't have @Body and @Field!"
        }

        // Function Signature
        let nameString = identifier
        let parametersString = parameters.map(\.signatureString).joined(separator: ", ")
        let signatureStatement = """
            func \(nameString)(\(parametersString)) async throws\(returnClause) {
            """

        // Request Initialization
        let decl = parameters.isEmpty ? "let" : "var"
        let requestStatement = """
            \(decl) req = \(newRequestFunction)(method: "\(method)", path: \(path))
            """

        // Request Construction
        let buildStatements = parameters.map(\.apiBuilderStatement)

        // Get Response
        let responseAssignment = returnType == nil ? "" : "let res = "
        let responseStatement = "\(responseAssignment)try await provider.request(req)"

        let lines: [String?] = [
           signatureStatement,
           requestStatement,
           buildStatements.joined(separator: "\n"),
           responseStatement,
           returnStatement,
           "}"
        ]

        return lines
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    private var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
}
