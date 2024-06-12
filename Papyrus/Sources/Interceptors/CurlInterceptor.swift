import Foundation

/// An `Interceptor` that logs requests based on a condition
public struct CurlLogger {
    public enum Condition {
        case always

        /// only log when the request encountered an error
        case onError
    }

    let logHandler: (String) -> Void
    let condition: Condition
    
    /// An `Interceptor` that calls a logHandler with a request based on a condition
    /// - Parameters:
    ///   - condition: must be met for the logging function to be called
    ///   - logHandler: a function that implements logging. defaults to `print()`
    public init(when condition: Condition, using logHandler: @escaping (String) -> Void = { print($0) }) {
        self.condition = condition
        self.logHandler = logHandler
    }
}

extension CurlLogger: Interceptor {
    public func intercept(req: PapyrusRequest, next: Next) async throws -> PapyrusResponse {
        if condition == .always {
            logHandler(req.curl(sortedHeaders: true))
        }

        do {
            let res = try await next(req)
            return res
        } catch {
            if condition == .onError {
                logHandler(req.curl(sortedHeaders: true))
            }
            throw error
        }
    }
}

public extension PapyrusRequest {
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
