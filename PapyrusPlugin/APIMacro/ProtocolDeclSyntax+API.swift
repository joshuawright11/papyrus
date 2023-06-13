import SwiftSyntax

extension ProtocolDeclSyntax {
    func createAPI() -> String {
        [
            """
            struct \(identifier.trimmed)API: \(identifier.trimmed) {
            let provider: Provider

            init(provider: Provider) {
                self.provider = provider
            }

            """,
            (apiFunctions + [createRequestFunction])
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n"),
            "}"
        ]
        .joined(separator: "\n")
    }

    var apiFunctions: [String] {
        let newRequestFunction = papyrusAttributes.isEmpty ? "PartialRequest" : "newRequest"
        return memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map { $0.apiFunction(newRequestFunction: newRequestFunction) }
    }

    private var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
    }

    private var createRequestFunction: String {
        guard !papyrusAttributes.isEmpty else {
            return ""
        }

        return """
        private func newRequest(method: String, path: String) -> PartialRequest {
            var req = PartialRequest(method: method, path: path)
            \(papyrusAttributes.map { $0.requestStatement(input: nil) }.joined(separator: "\n") )
            return req
        }
        """
    }
}
