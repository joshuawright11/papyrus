public class MethodAdapter: EndpointAdapter {
    public var method: String { _method }
    private let path: String
    private let _method: String
    
    public required init(method: String, path: String) {
        self._method = method
        self.path = path
    }
    
    public func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>) {
        endpoint.baseRequest.method = method
        endpoint.baseRequest.path = path
    }
}

extension Builder where Adapter: MethodAdapter {
    public init(wrappedValue: Wrapped, _ path: String) {
        self.init(wrappedValue: wrappedValue, Adapter(method: "CUSTOM", path: path))
    }
}

public typealias CUSTOM<Wrapped: EndpointBuilder> = Builder<Wrapped, CUSTOMAdaptor>
public final class CUSTOMAdaptor: MethodAdapter {}
public extension Builder where Adapter == CUSTOMAdaptor {
    init(wrappedValue: Wrapped, method: String, _ path: String) {
        self.init(wrappedValue: wrappedValue, Adapter(method: method, path: path))
    }
}

public typealias DELETE<Wrapped: EndpointBuilder> = Builder<Wrapped, DELETEAdapter>
public final class DELETEAdapter: MethodAdapter {
    public override var method: String { "DELETE" }
}

public typealias GET<Wrapped: EndpointBuilder> = Builder<Wrapped, GETAdapter>
public final class GETAdapter: MethodAdapter {
    public override var method: String { "GET" }
}

public typealias PATCH<Wrapped: EndpointBuilder> = Builder<Wrapped, PATCHAdapter>
public final class PATCHAdapter: MethodAdapter {
    public override var method: String { "PATCH" }
}

public typealias POST<Wrapped: EndpointBuilder> = Builder<Wrapped, POSTAdapter>
public final class POSTAdapter: MethodAdapter {
    public override var method: String { "POST" }
}

public typealias PUT<Wrapped: EndpointBuilder> = Builder<Wrapped, PUTAdapter>
public final class PUTAdapter: MethodAdapter {
    public override var method: String { "PUT" }
}

public typealias OPTIONS<Wrapped: EndpointBuilder> = Builder<Wrapped, OPTIONSAdapter>
public final class OPTIONSAdapter: MethodAdapter {
    public override var method: String { "OPTIONS" }
}

public typealias HEAD<Wrapped: EndpointBuilder> = Builder<Wrapped, HEADAdapter>
public final class HEADAdapter: MethodAdapter {
    public override var method: String { "HEAD" }
}

public typealias TRACE<Wrapped: EndpointBuilder> = Builder<Wrapped, TRACEAdapter>
public final class TRACEAdapter: MethodAdapter {
    public override var method: String { "TRACE" }
}

public typealias CONNECT<Wrapped: EndpointBuilder> = Builder<Wrapped, CONNECTAdapter>
public final class CONNECTAdapter: MethodAdapter {
    public override var method: String { "CONNECT" }
}
