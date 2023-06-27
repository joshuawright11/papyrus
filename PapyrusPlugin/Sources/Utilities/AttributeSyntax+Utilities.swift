import SwiftSyntax

extension AttributeSyntax {
    var firstArgument: String? {
        if case let .argumentList(list) = argument {
            return list.first?.expression.description.withoutQuotes
        }

        return nil
    }
}
