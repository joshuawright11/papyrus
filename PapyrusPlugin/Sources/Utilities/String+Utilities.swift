import SwiftSyntax

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var inQuotes: String {
        """
        "\(self)"
        """
    }
}
