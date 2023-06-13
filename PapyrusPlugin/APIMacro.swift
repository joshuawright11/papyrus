import SwiftSyntax
import SwiftSyntaxMacros

// TODO: Custom compiler errors
// TODO: Custom converters
// TODO: Static Headers
// TODO: KeyMapping
// TODO: Return a tuple with the Raw Response
// TODO: Alamofire
// TODO: Interceptor
// TODO: Tests
// TODO: Mocking (@Mock)
// TODO: Finish provider
// TODO: Final cleanup
// TODO: README.md

// TODO: Launch Twitter, HN, Swift Forums, r/swift, r/iOSProgramming Tuesday morning 9am

// TODO: Multipart

struct APIMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `protocol` = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        return [
            createAPI(for: `protocol`),
        ]
    }

    private static func createAPI(for protocol: ProtocolDeclSyntax) -> DeclSyntax {
        let protocolName = `protocol`.identifier.trimmed
        let functions = `protocol`.functions.map(\.apiFunction)
        return """
            struct \(protocolName)API: \(protocolName) {
            let provider: Provider

            init(provider: Provider) {
                self.provider = provider
            }

            \(raw: functions.joined(separator: "\n\n"))
            }
            """
    }
}

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }
}

extension ProtocolDeclSyntax {
    var functions: [FunctionDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }
}

extension FunctionDeclSyntax {
    var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
    }

    private var returnClause: String {
        guard let returnType else {
            return ""
        }

        return " -> \(returnType)"
    }

    private var returnType: String? {
        signature.output?.returnType.description
    }

    var apiFunction: String {
        guard isAsync, isThrows else {
            return "Not async throws!"
        }

        var method: String?
        var path: String?
        for attribute in papyrusAttributes {
            switch attribute {
            case let .http(_method, _path):
                guard method == nil, path == nil else {
                    return "Only one method per function!"
                }

                method = _method.withoutQuotes
                path = _path.withoutQuotes
            case .json:
                break
            case .formUrlEncoded:
                break
            case .headers:
                break
            default:
                // TODO: Move this to actual macros, to throw an error.
                return "\(attribute) isn't allowed on a function!"
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
            \(decl) req = PartialRequest(method: "\(method)", path: "\(path)")
            """

        // Request Construction
        let buildStatements = parameters.map(\.apiFunctionStatement)

        // Get Response
        let responseAssignment = returnType == nil ? "" : "let res = "
        let responseStatement = "\(responseAssignment)try await provider.request(req)"

        // Return Statement
        let returnStatement = returnType.map { "return try res.decodeContent(\($0).self)" }

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
            .joined(separator: "\n")
    }

    private var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    private var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
}

extension FunctionParameterSyntax {
    var isBody: Bool {
        for attribute in papyrusAttributes {
            if case .body = attribute {
                return true
            }
        }

        return false
    }

    var isField: Bool {
        for attribute in papyrusAttributes {
            switch attribute {
            case .field:
                return true
            case .body, .header, .path, .query:
                return false
            default:
                continue
            }
        }

        return true
    }

    var signatureString: String {
        let defaultArgument = defaultArgumentString.map { " = \($0)" } ?? ""
        let secondName = trimmed.secondName.map { "\($0)" } ?? ""
        return "\(trimmed.firstName)\(secondName): \(trimmed.type)\(defaultArgument)"
    }

    var defaultArgumentString: String? {
        for attribute in papyrusAttributes {
            if case .default(let value) = attribute {
                return value
            }
        }

        return nil
    }

    var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
    }

    var apiFunctionStatement: String {
        var statement: Attribute? = nil
        let name = (secondName ?? firstName).text
        for attribute in papyrusAttributes {
            switch attribute {
            case .body, .query, .header, .path, .field:
                guard statement == nil else {
                    return "Only one statement modifier per parameter!"
                }

                statement = attribute
            default:
                break
            }
        }

        return switch statement {
        case let .body(key):
            """
            req.addBody("\(key ?? name)", value: \(name))
            """
        case let .query(key):
            """
            req.addQuery("\(key ?? name)", value: \(name))
            """
        case let .header(key):
            """
            req.headers["\(key ?? name)"] = \(name)
            """
        case let .path(key):
            """
            req.parameters["\(key ?? name)"] = \(name)
            """
        case let .field(key):
            """
            req.addField("\(key ?? name)", value: \(name))
            """
        case .none:
            """
            req.addField("\(name)", value: \(name))
            """
        default:
            fatalError("Invalid statement type.")
        }
    }
}

enum Attribute {
    /// Type attributes
    case mock

    /// Type or Function attributes
    case json
    case formUrlEncoded
    case headers

    /// Function attributes
    case http(method: String, path: String)

    /// Parameter attributes
    case body(key: String? = nil)
    case field(key: String? = nil)
    case query(key: String? = nil)
    case header(key: String? = nil)
    case path(key: String? = nil)
    case `default`(value: String)

    init?(syntax: AttributeSyntax) {
        var firstArgument: String?
        var secondArgument: String?
        if case let .argumentList(list) = syntax.argument {
            firstArgument = list.first?.expression.description
            secondArgument = list.dropFirst().first?.expression.description
        }

        let name = syntax.attributeName.trimmedDescription
        switch name {
        case "GET2", "DELETE2", "PATCH2", "POST2", "PUT2", "OPTIONS2", "HEAD2", "TRACE2", "CONNECT2":
            guard let firstArgument else {
                return nil
            }

            self = .http(method: name, path: firstArgument)
        case "Http":
            guard let firstArgument, let secondArgument else {
                return nil
            }

            self = .http(method: secondArgument, path: firstArgument)
        case "Body2":
            self = .body(key: firstArgument?.withoutQuotes)
        case "Field2":
            self = .field(key: firstArgument?.withoutQuotes)
        case "Query2":
            self = .query(key: firstArgument?.withoutQuotes)
        case "Header2":
            self = .header(key: firstArgument?.withoutQuotes)
        case "Path2":
            self = .path(key: firstArgument?.withoutQuotes)
        case "Default":
            guard let firstArgument else {
                return nil
            }

            self = .`default`(value: firstArgument)
        default:
            return nil
        }
    }
}

extension [FunctionParameterSyntax] {
    func withAttribute(_ attribute: String?) -> [String] {
        compactMap { parameter -> String? in
            let attributes = parameter.attributes ?? []
            let name = parameter.secondName ?? parameter.firstName
            guard attributes.contains(where: { $0.trimmedDescription == attribute }) else {
                return nil
            }

            return name.text
        }
    }
}
