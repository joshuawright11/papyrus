import SwiftSyntax

extension ProtocolDeclSyntax {
    var accessModifier: String {
        guard let accessModifier = modifiers?.first?.trimmedDescription else {
            return ""
        }

        return "\(accessModifier) "
    }

    func createMock(_ customName: String?) -> String {
        let customName = customName.map { "final class \($0)" }
        let name = customName ?? "final class \(identifier.trimmed)Mock"
        return [
            """
            \(accessModifier)\(name): \(identifier.trimmed) {
            private let defaultError: Error
            private var mocks: [String: Any]

            \(accessModifier)init(defaultError: Error = PapyrusError("Not mocked")) {
                self.defaultError = defaultError
                self.mocks = [:]
            }

            """,
            createMockFunctions()
                .joined(separator: "\n\n"),
            "}"
        ]
        .joined(separator: "\n")
    }

    func createMockFunctions() -> [String] {
        functions.flatMap { $0.mockFunctions(accessLevel: accessModifier) }
    }

    func createAPI(_ customName: String?) -> String {
        let customName = customName.map { "struct \($0)" }
        let name = customName ?? "struct \(identifier.trimmed)API"
        return [
            """
            \(accessModifier)\(name): \(identifier.trimmed) {
            private let provider: Provider

            \(accessModifier)init(provider: Provider) {
                self.provider = provider
            }

            """,
            (createApiFunctions(accessLevel: accessModifier) + [newRequestFunction])
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n"),
            "}"
        ]
        .joined(separator: "\n")
    }

    func createApiFunctions(accessLevel: String) -> [String] {
        functions
            .map { $0.apiFunction(protocolAttributes: apiAttributes) }
            .map { accessModifier + $0 }
    }

    private var functions: [FunctionDeclSyntax] {
        return memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    private var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
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
}
