#if os(Linux)
import Papyrus

// This is so CI on Linux compiles

extension Provider {
    public convenience init(baseURL: String,
                            urlSession: URLSession = .shared,
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = []) {
        fatalError()
    }
}
#endif
