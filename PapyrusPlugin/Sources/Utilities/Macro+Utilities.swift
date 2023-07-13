import SwiftSyntax
import SwiftSyntaxMacros

extension Macro {
    static func handleError(_ closure: () throws -> String) -> [DeclSyntax] {
        do {
            return try [DeclSyntax(stringLiteral: closure())]
        } catch {
            return [DeclSyntax(stringLiteral: "\(error)")]
        }
    }
}
