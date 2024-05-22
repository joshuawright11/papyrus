import SwiftSyntax

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var inQuotes: String {
        "\"\(self)\""
    }

    // Need this since `capitalized` lowercases everything else.
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }
}
