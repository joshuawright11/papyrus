import SwiftSyntax

extension FunctionParameterSyntax {
    var variableName: String {
        (secondName ?? firstName).text
    }
}
