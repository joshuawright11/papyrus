import SwiftSyntax

extension String {
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }

    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var declSyntax: DeclSyntax {
        DeclSyntax(stringLiteral: self)
    }
}
