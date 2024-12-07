import SwiftSyntax

extension ProtocolDeclSyntax {
    var protocolName: String {
        name.text
    }
    
    var access: String? {
        modifiers.first?.trimmedDescription
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

    // MARK: Function effects & attributes

    var functionName: String {
        name.text
    }

    var effects: [String] {
        [signature.effectSpecifiers?.asyncSpecifier, signature.effectSpecifiers?.throwsClause?.throwsSpecifier]
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

    var returnsResponse: Bool {
        returnType == "Response"
    }

    var returnType: String? {
        signature.returnClause?.type.trimmedDescription
    }

    var returnsVoid: Bool {
        guard let returnType else {
            return true
        }

        return returnType == "Void"
    }
}

extension FunctionParameterSyntax {
    var label: String? {
        secondName != nil ? firstName.text : nil
    }

    var name: String {
        (secondName ?? firstName).text
    }

    var typeName: String {
        trimmed.type.description
    }
}

extension AttributeSyntax {
    var name: String {
        attributeName.trimmedDescription
    }

    var labeledArguments: [(label: String?, value: String)] {
        guard case let .argumentList(list) = arguments else {
            return []
        }

        return list.map {
            ($0.label?.text, $0.expression.description)
        }
    }
}
