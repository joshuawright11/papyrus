import SwiftSyntax

extension FunctionParameterSyntax {
    var isBody: Bool {
        for attribute in papyrusAttributes {
            if case .body = attribute {
                return true
            }
        }

        return false
    }

    var isField: Bool {
        for attribute in papyrusAttributes {
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
        let defaultArgument = defaultArgumentString.map { " = \($0)" } ?? ""
        let secondName = trimmed.secondName.map { "\($0)" } ?? ""
        return "\(trimmed.firstName)\(secondName): \(trimmed.type)\(defaultArgument)"
    }

    var defaultArgumentString: String? {
        for attribute in papyrusAttributes {
            if case .default(let value) = attribute {
                return value
            }
        }

        return nil
    }

    var papyrusAttributes: [Attribute] {
        attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap(Attribute.init) ?? []
    }

    var apiBuilderStatement: String? {
        var parameterAttribute: Attribute? = nil
        for attribute in papyrusAttributes {
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
