import SwiftSyntax

extension ProtocolDeclSyntax {

    func createMock() -> String {
        return [
            """
            final class \(identifier.trimmed)Mock: \(identifier.trimmed) {
            let defaultError: Error
            var mocks: [String: Any]

            init(defaultError: Error = PapyrusError("Not mocked")) {
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
        functions.flatMap(\.mockFunctions)
    }

    func createAPI() -> String {
        [
            """
            struct \(identifier.trimmed)API: \(identifier.trimmed) {
            let provider: Provider

            init(provider: Provider) {
                self.provider = provider
            }

            """,
            (createApiFunctions() + [newRequestFunction])
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n"),
            "}"
        ]
        .joined(separator: "\n")
    }

    func createApiFunctions() -> [String] {
        functions.map { $0.apiFunction(protocolAttributes: apiAttributes) }
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
        private func newRequest(method: String, path: String) -> RequestBuilder {
            var req = RequestBuilder(method: method, path: path)
            \(globalStatements.joined(separator: "\n") )
            return req
        }
        """
    }

    private var globalStatements: [String] {
        apiAttributes.compactMap { $0.requestStatement(input: nil) }
    }
}
