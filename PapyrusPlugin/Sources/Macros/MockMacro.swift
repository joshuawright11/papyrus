import SwiftSyntax
import SwiftSyntaxMacros

public struct MockMacro: PeerMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try [
            API.parse(declaration)
                .mockImplementation(suffix: attribute.name)
                .declSyntax()
        ]
    }
}

extension API {
    fileprivate func mockImplementation(suffix: String) -> Declaration {
        Declaration("final class \(name)\(suffix): \(name)") {
            "private let notMockedError: Error"
            "private var mocks: [String: Any]"

            Declaration("init(notMockedError: Error = PapyrusError(\"Not mocked\"))") {
                "self.notMockedError = notMockedError"
                "mocks = [:]"
            }
            .access(access)

            for endpoint in endpoints {
                endpoint.mockFunction().access(access)
                endpoint.mockerFunction().access(access)
            }
        }
        .access(access)
    }
}

extension API.Endpoint {
    fileprivate func mockFunction() -> Declaration {
        Declaration("func \(name)\(functionSignature)") {
            Declaration("guard let mocker = mocks[\(name.inQuotes)] as? \(mockClosureType) else") {
                "throw notMockedError"
            }

            let arguments = parameters.map(\.name).joined(separator: ", ")
            "return try await mocker(\(arguments))"
        }
    }

    fileprivate func mockerFunction() -> Declaration {
        Declaration("func mock\(name.capitalizeFirst)(mock: @escaping \(mockClosureType))") {
            "mocks[\(name.inQuotes)] = mock"
        }
    }

    private var mockClosureType: String {
        let parameterTypes = parameters.map(\.type).joined(separator: ", ")
        let returnType = responseType ?? "Void"
        return "(\(parameterTypes)) async throws -> \(returnType)"
    }
}
