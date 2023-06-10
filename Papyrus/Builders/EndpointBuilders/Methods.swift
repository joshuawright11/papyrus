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
        self.init(wrappedValue: wrappedValue, Adapter(method: "IGNORE", path: path))
    }
    
    public init<Req: EndpointRequest, Res: EndpointResponse>(_ path: String) where Wrapped == Endpoint<Req, Res> {
        self.init(wrappedValue: Endpoint<Req, Res>(), Adapter(method: "Ignore", path: path))
    }
}

public typealias CUSTOM<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, CUSTOMAdaptor>
public final class CUSTOMAdaptor: MethodAdapter {}
public extension Builder where Adapter == CUSTOMAdaptor {
    init(wrappedValue: Wrapped, method: String, _ path: String) {
        self.init(wrappedValue: wrappedValue, Adapter(method: method, path: path))
    }
    
    init<Req: EndpointRequest, Res: EndpointResponse>(method: String, _ path: String) where Wrapped == Endpoint<Req, Res> {
        self.init(wrappedValue: Endpoint<Req, Res>(), Adapter(method: method, path: path))
    }
}

public typealias DELETE<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, DELETEAdapter>
public final class DELETEAdapter: MethodAdapter {
    public override var method: String { "DELETE" }
}

public typealias GET<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, GETAdapter>
public final class GETAdapter: MethodAdapter {
    public override var method: String { "GET" }
}

public typealias PATCH<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, PATCHAdapter>
public final class PATCHAdapter: MethodAdapter {
    public override var method: String { "PATCH" }
}

public typealias POST<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, POSTAdapter>
public final class POSTAdapter: MethodAdapter {
    public override var method: String { "POST" }
}

public typealias PUT<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, PUTAdapter>
public final class PUTAdapter: MethodAdapter {
    public override var method: String { "PUT" }
}

public typealias OPTIONS<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, OPTIONSAdapter>
public final class OPTIONSAdapter: MethodAdapter {
    public override var method: String { "OPTIONS" }
}

public typealias HEAD<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, HEADAdapter>
public final class HEADAdapter: MethodAdapter {
    public override var method: String { "HEAD" }
}

public typealias TRACE<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, TRACEAdapter>
public final class TRACEAdapter: MethodAdapter {
    public override var method: String { "TRACE" }
}

public typealias CONNECT<Req: EndpointRequest, Res: EndpointResponse> = Builder<Endpoint<Req, Res>, CONNECTAdapter>
public final class CONNECTAdapter: MethodAdapter {
    public override var method: String { "CONNECT" }
}
