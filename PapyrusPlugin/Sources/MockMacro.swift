import SwiftSyntax
import SwiftSyntaxMacros

public struct MockMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try handleError {
            guard let type = declaration.as(ProtocolDeclSyntax.self) else {
                throw PapyrusPluginError("@Mock can only be applied to protocols.")
            }

            let name = node.firstArgument ?? "\(type.typeName)Mock"
            return try type.createMock(named: name)
        }
    }
}

extension ProtocolDeclSyntax {
    fileprivate func createMock(named mockName: String) throws -> String {
        """
        \(access)final class \(mockName): \(typeName) {
            private let notMockedError: Error
            private var mocks: [String: Any]

            \(access)init(notMockedError: Error = PapyrusError("Not mocked")) {
                self.notMockedError = notMockedError
                mocks = [:]
            }

        \(try generateMockFunctions())
        }
        """
    }

    private func generateMockFunctions() throws -> String {
        try functions
            .flatMap { try [$0.mockImplementation(), $0.mockerFunction] }
            .map { access + $0 }
            .joined(separator: "\n\n")
    }
}

extension FunctionDeclSyntax {
    fileprivate func mockImplementation() throws -> String {
        try validateSignature()

        let notFoundExpression: String
        switch style {
        case .concurrency:
            notFoundExpression = "throw notMockedError"
        case .completionHandler:
            guard let callbackName else {
                throw PapyrusPluginError("Missing @escaping completion handler as final function argument.")
            }

            let unimplementedError = returnResponseOnly ? ".error(notMockedError)" : ".failure(notMockedError)"
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
            func \(functionName)\(signature) {
                guard let mocker = mocks["\(functionName)"] as? \(mockClosureType) else {
                    \(notFoundExpression)
                }

                \(matchExpression)
            }
            """
    }

    fileprivate var mockerFunction: String {
        """
        func mock\(functionName.capitalizeFirst)(result: @escaping \(mockClosureType)) {
            mocks["\(functionName)"] = result
        }
        """
    }

    private var mockClosureType: String {
        let parameterTypes = parameters.map(\.typeString).joined(separator: ", ")
        let effects = effects.isEmpty ? "" : " \(effects.joined(separator: " "))"
        let returnType = signature.returnClause?.type.trimmedDescription ?? "Void"
        return "(\(parameterTypes))\(effects) -> \(returnType)"
    }
}

extension FunctionParameterSyntax {
    fileprivate var typeString: String {
        trimmed.type.description
    }
}

extension String {
    fileprivate var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }
}
