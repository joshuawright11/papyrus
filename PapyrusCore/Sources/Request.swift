import Foundation

public protocol Request {
    var url: URL? { get set }
    var method: String { get set }
    var headers: [String: String] { get set }
    var body: Data? { get set }
}

public extension Request {
    /// Create a cURL command from this instance
    ///
    /// - Parameter sortedHeaders: sort headers in output
    /// - Returns: cURL Command
    func curl(sortedHeaders: Bool = false) -> String {
        let lineSeparator = " \\\n"
        var components = [String]()

        // Add URL on same line
        if let url {
            components.append("curl '\(url.absoluteString)'")
        } else {
            components.append("curl")
        }

        // Add method
        components.append("-X \(method)")

        // Add headers
        let headerOptions = headers.map { "-H '\($0): \($1)'" }
        components += sortedHeaders ? headerOptions.sorted() : headerOptions

        // Add body
        if let body {
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            components.append("-d '\(bodyString)'")
        }

        return components.joined(separator: lineSeparator)
    }
}
