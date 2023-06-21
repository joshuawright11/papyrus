import Foundation
import SwiftSyntax

/// Async Preference
extension FunctionDeclSyntax {
    enum AsyncStyle {
        case concurrency
        case completionHandler
    }

    func validateSignature() throws {
        guard hasEscapingCompletion || hasAsyncAwait else {
            throw PapyrusPluginError("Function must either have `async throws` effects or an `@escaping` completion handler as the final argument.")
        }
    }

    var style: AsyncStyle {
        hasEscapingCompletion ? .completionHandler : .concurrency
    }

    private var hasEscapingCompletion: Bool {
        guard let parameter = parameters.last, returnType == nil else {
            return false
        }

        let type = parameter.type.trimmedDescription
        let isResult = type.hasPrefix("@escaping (Result<") && type.hasSuffix("Error>) -> Void")
        let isResponse = type == "@escaping (Response) -> Void"
        return isResult || isResponse
    }

    private var hasAsyncAwait: Bool {
        effects.contains("async") && effects.contains("throws")
    }
}

extension FunctionDeclSyntax {
    enum ReturnType: Equatable {
        struct TupleParameter: Equatable {
            let label: String?
            let type: String
        }

        case tuple([TupleParameter])
        case type(String)
    }

    // MARK: Function effects & attributes

    var name: String {
        identifier.text
    }

    var effects: [String] {
        [signature.effectSpecifiers?.asyncSpecifier, signature.effectSpecifiers?.throwsSpecifier]
            .compactMap { $0 }
            .map { $0.text }
    }

    var signatureString: String {
        """
        \(name)\(signature)
        """
    }

    var parameters: [FunctionParameterSyntax] {
        signature
            .input
            .parameterList
            .compactMap { $0.as(FunctionParameterSyntax.self) }
    }

    // MARK: Parameter Information

    var callbackName: String? {
        guard let parameter = parameters.last, style == .completionHandler else {
            return nil
        }

        return parameter.variableName
    }

    private var callbackType: String? {
        guard let parameter = parameters.last, returnType == nil else {
            return nil
        }

        let type = parameter.type.trimmedDescription
        /// This shouldn't be string based.
        if type == "@escaping (Response) -> Void" {
            return "Response"
        } else {
            return type
                .replacingOccurrences(of: "@escaping (Result<", with: "")
                .replacingOccurrences(of: ", Error>) -> Void", with: "")
        }
    }

    // MARK: Return Data

    var returnTypeString: String? {
        signature.output?.returnType.trimmedDescription
    }

    var responseType: ReturnType? {
        if style == .completionHandler, let callbackType {
            return .type(callbackType)
        }

        return returnType
    }

    private var returnType: ReturnType? {
        guard let type = signature.output?.returnType else {
            return nil
        }

        if let type = type.as(TupleTypeSyntax.self) {
            return .tuple(type.elements.map { .init(label: $0.name?.text, type: $0.type.trimmedDescription) })
        } else {
            return .type(type.trimmedDescription)
        }
    }

    var returnExpression: String? {
        switch responseType {
        case .tuple(let array):
            let elements = array.map { element in
                let decodeElement = element.type == "Response" ? "res" : "try req.responseDecoder.decode(\(element.type).self, from: res)"
                return [
                    element.label,
                    decodeElement
                ]
                .compactMap { $0 }
                .joined(separator: ": ")
            }
            return """
                (
                    \(elements.joined(separator: ",\n"))
                )
                """
        case .type(let string) where string != "Response":
            return "try req.responseDecoder.decode(\(string).self, from: res)"
        default:
            return nil
        }
    }

    var returnsResponse: Bool {
        responseType == .type("Response")
    }
}
