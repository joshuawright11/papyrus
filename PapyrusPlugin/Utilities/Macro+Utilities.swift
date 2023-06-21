import SwiftSyntax
import SwiftSyntaxMacros

extension Macro {
    static func handleError(_ closure: () throws -> String) -> [DeclSyntax] {
        do {
            return [try closure().declSyntax]
        } catch {
            return ["\(error)".declSyntax]
        }
    }
}
