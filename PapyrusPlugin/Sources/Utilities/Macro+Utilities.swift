import SwiftSyntax
import SwiftSyntaxMacros

extension Macro {
    static func handleError(_ closure: () throws -> String) -> [DeclSyntax] {
        do {
            return [DeclSyntax(stringLiteral: try closure())]
        } catch {
            return [DeclSyntax(stringLiteral: "\(error)")]
        }
    }
}
