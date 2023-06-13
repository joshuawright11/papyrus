import SwiftSyntax

extension ProtocolDeclSyntax {

    func createMock() -> String? {
        guard papyrusAttributes.contains(where: { attribute in
            if case .mock = attribute {
                return true
            } else {
                return false
            }
        }) else {
            return nil
        }

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
        let newRequestFunction = globalStatements.isEmpty ? "PartialRequest" : "newRequest"
        return functions.map { $0.apiFunction(newRequestFunction: newRequestFunction) }
    }

    private var functions: [FunctionDeclSyntax] {
        return memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    private var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
    }

    private var newRequestFunction: String {
        guard !globalStatements.isEmpty else {
            return ""
        }

        return """
        private func newRequest(method: String, path: String) -> PartialRequest {
            var req = PartialRequest(method: method, path: path)
            \(globalStatements.joined(separator: "\n") )
            return req
        }
        """
    }

    private var globalStatements: [String] {
        papyrusAttributes.compactMap { $0.requestStatement(input: nil) }
    }
}
