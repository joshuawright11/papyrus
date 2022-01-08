class MethodAdapter: EndpointAdapter {
    var method: String { _method }
    private let path: String
    private let _method: String
    
    required init(method: String, path: String) {
        self._method = method
        self.path = path
    }
    
    func adapt<Req: EndpointRequest, Res: Codable>(endpoint: inout Endpoint<Req, Res>) {
        endpoint.method = method
        endpoint.path = path
    }
}

extension Builder where Adapter: MethodAdapter {
    init(wrappedValue: Wrapped, _ path: String) {
        self.init(wrappedValue: wrappedValue, Adapter(method: "CUSTOM", path: path))
    }
}
