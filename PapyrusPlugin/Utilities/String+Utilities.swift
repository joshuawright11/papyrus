import SwiftSyntax

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }
}
