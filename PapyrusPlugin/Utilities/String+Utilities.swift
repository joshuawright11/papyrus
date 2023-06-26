import SwiftSyntax

extension String {
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }

    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    mutating func appendNewLine(_ string: String) {
        append("\n" + string)
    }

    var declSyntax: DeclSyntax {
        DeclSyntax(stringLiteral: self)
    }
}
