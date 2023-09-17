import SwiftSyntax

extension AttributeSyntax {
    var firstArgument: String? {
        if case let .argumentList(list) = arguments {
            return list.first?.expression.description.withoutQuotes
        }

        return nil
    }
}
