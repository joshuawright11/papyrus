import SwiftSyntax

extension FunctionParameterSyntax {
    var isCallback: Bool {
        type.as(AttributedTypeSyntax.self)?.baseType.is(FunctionTypeSyntax.self) ?? false
    }

    var isBody: Bool {
        for attribute in apiAttributes {
            if case .body = attribute {
                return true
            }
        }

        return false
    }

    var isField: Bool {
        for attribute in apiAttributes {
            switch attribute {
            case .field:
                return true
            case .body, .header, .path, .query:
                return false
            default:
                continue
            }
        }

        return true
    }

    var closureSignatureString: String {
        trimmed.type.description
    }

    var signatureString: String {
        let secondName = trimmed.secondName.map { "\($0)" } ?? ""
        return "\(trimmed.firstName)\(secondName): \(trimmed.type)"
    }

    var apiAttributes: [APIAttribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(APIAttribute.init) ?? []
    }

    var apiBuilderStatement: String? {
        guard !isCallback else {
            return nil
        }

        var parameterAttribute: APIAttribute? = nil
        for attribute in apiAttributes {
            switch attribute {
            case .body, .query, .header, .path, .field:
                guard parameterAttribute == nil else {
                    return "Only one attribute per parameter!"
                }

                parameterAttribute = attribute
            default:
                break
            }
        }

        let input = (secondName ?? firstName).text
        let attribute = parameterAttribute ?? .field(key: nil)
        return attribute.requestStatement(input: input)
    }
}
