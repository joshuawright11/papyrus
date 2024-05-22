import SwiftSyntax

extension ProtocolDeclSyntax {
    var protocolName: String {
        name.text
    }
    
    var access: String {
        modifiers.first.map { "\($0.trimmedDescription) " } ?? ""
    }

    var functions: [FunctionDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    var protocolAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}

extension FunctionDeclSyntax {
    enum ReturnType {
        case tuple([(label: String?, type: String)])
        case type(String)
    }

    // MARK: Function effects & attributes

    var functionName: String {
        name.text
    }

    var effects: [String] {
        [signature.effectSpecifiers?.asyncSpecifier, signature.effectSpecifiers?.throwsSpecifier]
            .compactMap { $0 }
            .map { $0.text }
    }

    var parameters: [FunctionParameterSyntax] {
        signature
            .parameterClause
            .parameters
            .compactMap { FunctionParameterSyntax($0) }
    }

    var functionAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }

    // MARK: Return Data

    var returnResponseOnly: Bool {
        if case .type("Response") = returnType {
            return true
        } else {
            return false
        }
    }

    var returnType: ReturnType? {
        guard let type = signature.returnClause?.type else {
            return nil
        }

        if let type = type.as(TupleTypeSyntax.self) {
            return .tuple(
                type.elements
                    .map { (label: $0.firstName?.text, type: $0.type.trimmedDescription) }
            )
        } else {
            return .type(type.trimmedDescription)
        }
    }
}

extension FunctionParameterSyntax {
    var name: String {
        (secondName ?? firstName).text
    }

    var typeName: String {
        trimmed.type.description
    }
}

extension AttributeSyntax {
    var firstArgument: String? {
        if case let .argumentList(list) = arguments {
            return list.first?.expression.description.withoutQuotes
        }

        return nil
    }
}
