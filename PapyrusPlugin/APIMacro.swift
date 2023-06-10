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
            // TODO: Throw Error if no async throws
            return "No async throws!"
        }

        guard let attribute = function.attributes?.first?.as(AttributeSyntax.self) else {
            // TODO: Throw Error if no method
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
            .map { $0.trimmed.description }
            .joined()
        let returnString = returnClause.map { "-> \($0.returnType.description)" } ?? ""

        // Request Parts
        let method = attribute.attributeName.description
        let path = argument.description.filter { $0 != "\"" }
        let decodeType = returnClause.map { "\($0.returnType.description).self" } ?? "Void"

        // Headers

        let headers = parameters
            .compactMap { parameter -> String? in
                let attributes = parameter.attributes ?? []
                let name = parameter.firstName

                guard attributes.contains(where: { $0.trimmedDescription == "@Header2" }) else {
                    return nil
                }

                return name.text
            }

        let headerString = headers.isEmpty ? "" : """
        
        headers: [
        \(headers.map { "\"\($0)\":\($0)" }.joined(separator: ",\n"))
        ],
        """

        // Queries

        let queries = parameters
            .compactMap { parameter -> String? in
                let attributes = parameter.attributes ?? []
                let name = parameter.firstName
                guard attributes.contains(where: { $0.trimmedDescription == "@Query2" }) else {
                    return nil
                }

                return name.text
            }

        let queryString = queries.isEmpty ? "" : """

        queries: [
        \(queries.map { "\"\($0)\":\($0)" }.joined(separator: ",\n"))
        ],
        """

        // Parameters

        let pathParameters = parameters
            .compactMap { parameter -> String? in
                let attributes = parameter.attributes ?? []
                let name = parameter.firstName
                guard attributes.contains(where: { $0.trimmedDescription == "@Path2" }) else {
                    return nil
                }

                return name.text
            }

        let pathString = pathParameters.isEmpty ? "" : """

        parameters: [
        \(pathParameters.map { "\"\($0)\":\($0)" }.joined(separator: ",\n"))
        ],
        """

        // Body

        let fieldParameters = parameters
            .compactMap { parameter -> String? in
                let attributes = parameter.attributes ?? []
                let name = parameter.firstName
                guard attributes.contains(where: { $0.trimmedDescription == "@Field2" }) else {
                    return nil
                }

                return name.text
            }

        let fieldString = fieldParameters.isEmpty ? "" : """

        body: [
        \(fieldParameters.map { "\"\($0)\":\($0)" }.joined(separator: ",\n"))
        ],
        """

        // TODO: Fields
        // TODO: Body
        // TODO: Fix Spacing

        return """
               func \(nameString)(\(parametersString)) async throws \(returnString) {
                   let res = try await provider.request(
                       method: "\(method)",
                       path: "\(path)",\(pathString)\(queryString)\(headerString)
                       body: nil
                   )
                   return try res.decodeContent(\(decodeType))
               }
               """
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
