import SwiftSyntax
import SwiftSyntaxMacros

public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            throw PapyrusPluginError("@Mock can only be applied to protocols.")
        }

        return [
            try proto
                .mockService(named: "\(proto.protocolName)\(node.attributeName)")
                .declSyntax()
        ]
    }
}

extension ProtocolDeclSyntax {
    fileprivate func mockService(named mockName: String) throws -> Declaration {
        try Declaration("\(access)final class \(mockName): \(protocolName), @unchecked Sendable") {
            "private let notMockedError: Error"
            "private var mocks: [String: Any]"

            Declaration("\(access)init(notMockedError: Error = PapyrusError(\"Not mocked\"))") {
                "self.notMockedError = notMockedError"
                "mocks = [:]"
            }

            for function in functions {
                try function.mockEndpointFunction(access: access)

                function.mockerFunction(access: access)
            }
        }
    }
}

extension FunctionDeclSyntax {
    fileprivate func mockEndpointFunction(access: String) throws -> Declaration {
        guard effects == ["async", "throws"] else {
            throw PapyrusPluginError("Function signature must have `async throws`.")
        }

        return Declaration("\(access)func \(functionName)\(signature)") {
            Declaration("guard let mocker = mocks[\(functionName.inQuotes)] as? \(mockClosureType) else") {
                "throw notMockedError"
            }

            ""

            let mockerArguments = parameters.map(\.name).joined(separator: ", ")
            "return try await mocker(\(mockerArguments))"
        }
    }

    fileprivate func mockerFunction(access: String) -> Declaration {
        Declaration("\(access)func mock\(functionName.capitalizeFirst)(mock: @escaping \(mockClosureType))") {
            "mocks[\(functionName.inQuotes)] = mock"
        }
    }

    private var mockClosureType: String {
        let parameterTypes = parameters.map(\.typeName).joined(separator: ", ")
        let returnType = signature.returnClause?.type.trimmedDescription ?? "Void"
        return "(\(parameterTypes)) async throws -> \(returnType)"
    }
}
