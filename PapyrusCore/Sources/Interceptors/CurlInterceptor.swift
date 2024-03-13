import Foundation

/// An `Interceptor` that logs requests based on a condition
public struct CurlLogger {
    public enum Condition {
        case always

        /// only log when the request encountered an error
        case onError
    }

    let loggingFn: (String) -> Void
    let condition: Condition
    
    /// An `Interceptor` that calls a loggingFn with a request based on a condition
    /// - Parameters:
    ///   - condition: must be met for the logging function to be called
    ///   - loggingFn: a function that implements logging. defaults to `print()`
    public init(when condition: Condition, using loggingFn: @escaping (String) -> Void = { print($0) }) {
        self.condition = condition
        self.loggingFn = loggingFn
    }
}

extension CurlLogger: Interceptor {
    public func intercept(req: any Request, next: (any Request) async throws -> any Response) async throws -> any Response {
        if condition == .always {
            loggingFn(req.curl(sortedHeaders: true))
        }

        do {
            let res = try await next(req)
            return res
        } catch {
            if condition == .onError {
                loggingFn(req.curl(sortedHeaders: true))
            }
            throw error
        }
    }
}
