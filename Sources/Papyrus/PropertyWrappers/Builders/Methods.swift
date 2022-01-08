typealias CUSTOM<Wrapped: EndpointBuilder> = Builder<Wrapped, CUSTOMAdaptor>
final class CUSTOMAdaptor: MethodAdapter {}
extension Builder where Adapter == CUSTOMAdaptor {
    init(wrappedValue: Wrapped, method: String, _ path: String) {
        self.init(wrappedValue: wrappedValue, Adapter(method: method, path: path))
    }
}

typealias DELETE<Wrapped: EndpointBuilder> = Builder<Wrapped, DELETEAdapter>
final class DELETEAdapter: MethodAdapter {
    override var method: String { "DELETE" }
}

typealias GET<Wrapped: EndpointBuilder> = Builder<Wrapped, GETAdapter>
final class GETAdapter: MethodAdapter {
    override var method: String { "GET" }
}

typealias PATCH<Wrapped: EndpointBuilder> = Builder<Wrapped, PATCHAdapter>
final class PATCHAdapter: MethodAdapter {
    override var method: String { "PATCH" }
}

typealias POST<Wrapped: EndpointBuilder> = Builder<Wrapped, POSTAdapter>
final class POSTAdapter: MethodAdapter {
    override var method: String { "POST" }
}

typealias PUT<Wrapped: EndpointBuilder> = Builder<Wrapped, PUTAdapter>
final class PUTAdapter: MethodAdapter {
    override var method: String { "PUT" }
}
