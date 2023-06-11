import SwiftSyntax
import SwiftSyntaxMacros

struct APIMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let type = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        let functions = type
            .memberBlock
            .members
            .compactMap { member in
                member.decl.as(FunctionDeclSyntax.self)
            }
            .map(generateAPIFunction)

        let functionsString = functions.joined(separator: "\n\n")

        return [
            """
            struct \(type.identifier.trimmed)API: \(type.identifier) {
                let provider: Provider

                init(provider: Provider) {
                    self.provider = provider
                }

            \(raw: functionsString)
            }
            """,
        ]
    }

    static private func generateAPIFunction(function: FunctionDeclSyntax) -> String {
        guard
            function.signature.effectSpecifiers?.asyncSpecifier != nil,
            function.signature.effectSpecifiers?.throwsSpecifier != nil
        else {
            return "No async throws!"
        }

        guard let attribute = function.attributes?.first?.as(AttributeSyntax.self) else {
            return "No method!"
        }

        guard let argument = attribute.argument else {
            return "No argument!"
        }

        // Inputs
        let parameters = function.signature.input.parameterList
        let returnClause = function.signature.output

        // Function parts
        let nameString = function.identifier
        let parametersString = parameters
            .map { $0.trimmed }
            .map { value in
                let secondName = value.secondName.map { "\($0)" } ?? ""
                return "\(value.firstName)\(secondName): \(value.type)"
            }
            .joined(separator: ", ")
        let returnString = returnClause.map { "-> \($0.returnType.description)" } ?? ""

        // Request Parts
        let method = attribute.attributeName.description
        let path = argument.description.filter { $0 != "\"" }
        let decodeType = returnClause.map { "\($0.returnType.description).self" } ?? "Void"

        // Headers
        let headers = parameters.withAttribute("@Header2")
        let headerStatements = headers.map {
            """
                req.headers["\($0)"] = \($0)
            """
        }

        // Queries
        let queries = parameters.withAttribute("@Query2")
        let queryStatements = queries.map {
            """
                req.addQuery("\($0)", value: \($0))
            """
        }

        // Parameters
        let pathParameters = parameters.withAttribute("@Path2")
        let pathStatements = pathParameters.map {
            """
                req.parameters["\($0)"] = \($0)
            """
        }

        // Fields
        let fields = parameters.withAttribute("@Field2") + parameters.withAttribute(nil)
        let fieldStatements = fields.map {
            """
                req.addField("\($0)", value: \($0))
            """
        }

        // Body
        let bodies = parameters.withAttribute("@Body2")
        let bodyStatements = bodies.map {
            """
                req.addBody("\($0)", value: \($0))
            """
        }

        guard bodyStatements.count <= 1 else {
            return "Can only have one @Body!"
        }

        guard bodyStatements.isEmpty || fields.isEmpty else {
            return "Can't have @Body and @Field!"
        }

        let isMutating = !(headers.isEmpty && queries.isEmpty && pathParameters.isEmpty && fields.isEmpty && bodies.isEmpty)
        let decl = isMutating ? "var" : "let"
        let statements = headerStatements + queryStatements + pathStatements + fieldStatements + bodyStatements
        let statementsString = statements.isEmpty ? "" : """
        
        \(statements.joined(separator: "\n"))
        """

        // TODO: Custom names
        // TODO: Custom compiler errors
        // TODO: Custom converters

        return """
               func \(nameString)(\(parametersString)) async throws \(returnString) {
                   \(decl) req = PartialRequest(method: "\(method)", path: "\(path)")\(statementsString)
                   let res = try await provider.request(req)
                   return try res.decodeContent(\(decodeType))
               }
               """
    }
}

extension FunctionParameterListSyntax {
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

extension APIMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return ["associatedtype Foo = String"]
    }
}

/// KILL THIS.
extension APIMacro: ConformanceMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [("APIProvider", nil)]
    }
}
