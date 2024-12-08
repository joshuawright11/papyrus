import Foundation
import SwiftSyntax

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var inQuotes: String {
        "\"\(self)\""
    }

    var inParentheses: String {
        "(\(self))"
    }

    // Need this since `capitalized` lowercases everything else.
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }

    var papyrusPathParameters: [String] {
        components(separatedBy: "/").compactMap(\.extractParameter)
    }

    private var extractParameter: String? {
        if hasPrefix(":") {
            String(dropFirst())
        } else if hasPrefix("{") && hasSuffix("}") {
            String(dropFirst().dropLast())
        } else {
            nil
        }
    }
}
