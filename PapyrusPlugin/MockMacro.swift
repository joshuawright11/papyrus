import SwiftSyntax
import SwiftSyntaxMacros

struct MockMacro: PeerMacro {
    static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        handleError {
            guard let type = declaration.as(ProtocolDeclSyntax.self) else {
                throw PapyrusPluginError("@Mock can only be applied to protocols.")
            }

            return try type.createMock(named: node.firstArgument)
        }
    }
}

extension ProtocolDeclSyntax {
    fileprivate func createMock(named customName: String?) throws -> String {
        let typeName = customName ?? "\(name)Mock"
        let functions = try createMockFunctions().map { access + $0 }
        return access + """
            final class \(typeName): \(name) {
                private let defaultError: Error
                private var mocks: [String: Any]

                \(access)init(defaultError: Error = PapyrusError("Not mocked")) {
                    self.defaultError = defaultError
                    mocks = [:]
                }

            \(functions.joined(separator: "\n\n"))
            }
            """
    }

    private func createMockFunctions() throws -> [String] {
        try functions.flatMap {
            try [$0.mockedFunction(), $0.mockerFunction]
        }
    }
}

extension FunctionDeclSyntax {
    fileprivate func mockedFunction() throws -> String {
        try validateSignature()

        let notFoundExpression: String
        switch style {
        case .concurrency:
            notFoundExpression = "throw defaultError"
        case .completionHandler:
            guard let callbackName else {
                throw PapyrusPluginError("Missing @escaping completion handler as final function argument.")
            }

            let unimplementedError = returnsResponse ? ".error(defaultError)" : ".failure(defaultError)"
            notFoundExpression = """
                \(callbackName)(\(unimplementedError))
                return
                """
        }

        let mockerArguments = parameters.map(\.variableName).joined(separator: ", ")
        let matchExpression: String =
            switch style {
            case .concurrency:
                "return try await mocker(\(mockerArguments))"
            case .completionHandler:
                "mocker(\(mockerArguments))"
            }

        return """
            func \(signatureString) {
                guard let mocker = mocks["\(name)"] as? \(closureTypeString) else {
                    \(notFoundExpression)
                }

                \(matchExpression)
            }
            """
    }

    fileprivate var mockerFunction: String {
        """
        func mock\(name.capitalizeFirst)(result: @escaping \(closureTypeString)) {
            mocks["\(name)"] = result
        }
        """
    }

    private var closureTypeString: String {
        let parameterTypes = parameters.map(\.typeString).joined(separator: ", ")
        let effects = effects.isEmpty ? "" : " \(effects.joined(separator: " "))"
        let returnType = returnTypeString ?? "Void"
        return "(\(parameterTypes))\(effects) -> \(returnType)"
    }
}
