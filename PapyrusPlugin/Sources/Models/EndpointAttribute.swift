import SwiftSyntax

/// To be parsed from protocol and function attributes. Modifies requests /
/// responses in some way.
enum EndpointAttribute {
    case json(encoder: String, decoder: String)
    case urlForm(encoder: String)
    case multipart(encoder: String)
    case converter(encoder: String, decoder: String)
    case keyMapping(value: String)
    case headers(value: String)
    case authorization(value: String)

    init?(_ attribute: AttributeSyntax) {
        let arguments = attribute.labeledArguments
        let firstArgument = arguments.first?.value
        let secondArgument = arguments.count > 1 ? arguments[1].value : nil
        switch attribute.name {
        case "Headers":
            guard let firstArgument else { return nil }
            self = .headers(value: firstArgument)
        case "JSON":
            let encoder = arguments.first(where: { $0.label == "encoder" })?.value ?? "JSONEncoder()"
            let decoder = arguments.first(where: { $0.label == "decoder" })?.value ?? "JSONDecoder()"
            self = .json(encoder: encoder, decoder: decoder)
        case "URLForm":
            self = .urlForm(encoder: firstArgument ?? "URLEncodedFormEncoder()")
        case "Multipart":
            self = .multipart(encoder: firstArgument ?? "MultipartEncoder()")
        case "Coder":
            guard let firstArgument, let secondArgument else { return nil }
            self = .converter(encoder: firstArgument, decoder: secondArgument)
        case "KeyMapping":
            guard let firstArgument else { return nil }
            self = .keyMapping(value: firstArgument)
        case "Authorization":
            guard let firstArgument else { return nil }
            self = .authorization(value: firstArgument)
        default:
            return nil
        }
    }
}
