import SwiftSyntax
import SwiftSyntaxMacros

extension Macro {
    static func handleError(_ closure: () throws -> String) throws -> [DeclSyntax] {
        [DeclSyntax(stringLiteral: try closure())]
    }
}
