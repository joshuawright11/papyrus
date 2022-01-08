public protocol EndpointBuilder {
    associatedtype Wrapped: EndpointBuilder where Wrapped.Request == Request, Wrapped.Response == Response
    associatedtype Request: EndpointRequest
    associatedtype Response: EndpointResponse
    
    var build: (inout Endpoint<Request, Response>) -> Void { get set }
}

extension EndpointBuilder {
    public func withBuilder(build: @escaping (inout Endpoint<Request, Response>) -> Void) -> Self {
        var copy = self
        let oldBuild = copy.build
        copy.build = {
            build(&$0)
            oldBuild(&$0)
        }
        
        return copy
    }
}

extension Endpoint: EndpointBuilder {
    public typealias Wrapped = Self
    
    public var build: (inout Endpoint<Request, Response>) -> Void {
        get { { _ in } }
        set { newValue(&self) }
    }
}
