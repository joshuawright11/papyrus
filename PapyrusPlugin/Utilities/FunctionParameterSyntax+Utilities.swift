import SwiftSyntax

extension FunctionParameterSyntax {
    var variableName: String {
        (secondName ?? firstName).text
    }

    var typeString: String {
        trimmed.type.description
    }

    var signatureString: String {
        let secondName = trimmed.secondName.map { "\($0)" } ?? ""
        return "\(trimmed.firstName)\(secondName): \(trimmed.type)"
    }
}
