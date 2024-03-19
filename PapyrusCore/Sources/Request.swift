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
        if sortedHeaders {
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                components.append("-H '\(key): \(value)'")
            }
        } else {
            for (key, value) in headers {
                components.append("-H '\(key): \(value)'")
            }
        }

        // Add body
        if let bodyData = body {
            let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
            components.append("-d '\(bodyString)'")
        }

        return components.joined(separator: lineSeparator)
    }
}
