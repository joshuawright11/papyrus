import SwiftSyntax

struct Declaration: ExpressibleByStringLiteral {
    let text: String
    /// Declarations inside a closure following `text`.
    let nested: [Declaration]?

    init(stringLiteral value: String) {
        self.init(value, nested: nil)
    }

    init(_ text: String, nested: [Declaration]? = nil) {
        self.text = text
        self.nested = nested
    }

    init(_ text: String, @DeclarationsBuilder nested: () throws -> [Declaration]) rethrows {
        self.text = text
        self.nested = try nested()
    }

    func formattedString() -> String {
        guard let nested else {
            return text
        }

        let nestedOrdered = isType ? nested.organized() : nested
        let nestedFormatted = nestedOrdered
            .map { declaration in
                declaration
                    .formattedString()
                    .replacingOccurrences(of: "\n", with: "\n\t")
            }

        let nestedText = nestedFormatted.joined(separator: "\n\t")
        return """
        \(text) {
        \t\(nestedText)
        }
        """
        // Using \t screws up macro syntax highlighting
        .replacingOccurrences(of: "\t", with: "    ")
    }

    func declSyntax() -> DeclSyntax {
        DeclSyntax(stringLiteral: formattedString())
    }
}

extension [Declaration] {
    /// Reorders declarations in the following manner:
    ///
    /// 1. Properties (public -> private)
    /// 2. initializers (public -> private)
    /// 3. functions (public -> private)
    ///
    /// Properties have no newlines between them, functions have a single, blank
    /// newline between them.
    fileprivate func organized() -> [Declaration] {
        self
            .sorted()
            .spaced()
    }

    private func sorted() -> [Declaration] {
        sorted { $0.sortValue < $1.sortValue }
    }

    private func spaced() -> [Declaration] {
        var declarations: [Declaration] = []
        for declaration in self {
            defer { declarations.append(declaration) }
            
            guard let last = declarations.last else {
                continue
            }

            if last.isType {
                declarations.append(.newline)
            } else if last.isProperty && !declaration.isProperty {
                declarations.append(.newline)
            } else if last.isFunction || last.isInit {
                declarations.append(.newline)
            }
        }

        return declarations
    }
}

extension Declaration {
    fileprivate var sortValue: Int {
        if isType {
            0 + accessSortValue
        } else if isProperty {
            10 + accessSortValue
        } else if isInit {
            20 + accessSortValue
        } else if !isStaticFunction {
            40 + accessSortValue
        } else {
            50 + accessSortValue
        }
    }

    var accessSortValue: Int {
        if text.contains("open") {
            0
        } else if text.contains("public") {
            1
        } else if text.contains("package") {
            2
        } else if text.contains("fileprivate") {
            4
        } else if text.contains("private") {
            5
        } else {
            3 // internal (either explicit or implicit)
        }
    }

    fileprivate var isType: Bool {
        text.contains("enum") ||
        text.contains("struct") ||
        text.contains("protocol") || 
        text.contains("actor") ||
        text.contains("class") ||
        text.contains("typealias")
    }

    fileprivate var isProperty: Bool {
        text.contains("let") || text.contains("var")
    }

    fileprivate var isStaticFunction: Bool {
        (text.contains("static") || text.contains("class")) && isFunction
    }

    fileprivate var isFunction: Bool {
        text.contains("func") && text.contains("(") && text.contains(")")
    }

    fileprivate var isInit: Bool {
        text.contains("init(")
    }
}

extension Declaration {
    static let newline: Declaration = ""
}

@resultBuilder
struct DeclarationsBuilder {
    protocol Block {
        var declarations: [Declaration] { get }
    }

    static func buildBlock(_ components: Block...) -> [Declaration] {
        components.flatMap(\.declarations)
    }

    // MARK: Declaration literals

    static func buildExpression(_ expression: Declaration) -> Declaration {
        expression
    }

    static func buildExpression(_ expression: [Declaration]) -> [Declaration] {
        expression
    }

    static func buildExpression(_ expression: [Declaration]?) -> [Declaration] {
        expression ?? []
    }

    // MARK: `String` literals

    static func buildExpression(_ expression: String) -> Declaration {
        Declaration(expression)
    }

    static func buildExpression(_ expression: [String]) -> [Declaration] {
        expression.map { Declaration($0) }
    }

    // MARK: `for`

    static func buildArray(_ components: [Declaration]) -> [Declaration] {
        components
    }

    static func buildArray(_ components: [[Declaration]]) -> [Declaration] {
        components.flatMap { $0 }
    }

    // MARK: `if`

    static func buildEither(first components: [Declaration]) -> [Declaration] {
        components
    }

    static func buildEither(second components: [Declaration]) -> [Declaration] {
        components
    }

    // MARK: `Optional`

    static func buildOptional(_ component: [Declaration]?) -> [Declaration] {
        component ?? []
    }
}

extension Declaration: DeclarationsBuilder.Block {
    var declarations: [Declaration] { [self] }
}

extension [Declaration]: DeclarationsBuilder.Block {
    var declarations: [Declaration] { self }
}
