import Foundation
import Papyrus

struct TestAPI: API {
    let baseURL: String = "http://localhost"
    var keyMapping: KeyMapping = .useDefaultKeys
    
    @POST("/query")
    var query = Endpoint<QueryRequest, Empty>()
    
    @POST("/queryInPath?key2=value2")
    var queryInPath = Endpoint<QueryRequest, Empty>()
    
    @URLForm
    @POST("/url")
    var url = Endpoint<Empty, Empty>()
    
    @URLForm
    @HeaderWrapper
    @HeaderWrapper(name: "one", value: "1")
    @HeaderWrapper(name: "two", value: "2")
    @HeaderWrapper(name: "three", value: "3")
    @HeaderWrapper(name: "four", value: "4")
    @HeaderWrapper(name: "five", value: "5")
    @PUT("/body")
    var stacked = Endpoint<Empty, Empty>()
    
    @URLForm
    @JSON
    @PUT("/body")
    var override = Endpoint<Empty, Empty>()
    
    @GET    <Empty, Empty>("/get")                var get
    @DELETE <Empty, Empty>("/delete")             var delete
    @PATCH  <Empty, Empty>("/patch")              var patch
    @POST   <Empty, Empty>("/post")               var post
    @PUT    <Empty, Empty>("/put")                var put
    @OPTIONS<Empty, Empty>("/options")            var options
    @TRACE  <Empty, Empty>("/trace")              var trace
    @CONNECT<Empty, Empty>("/connect")            var connect
    @HEAD   <Empty, Empty>("/head")               var head
    @CUSTOM <Empty, Empty>(method: "FOO", "/foo") var custom
}

struct QueryRequest: EndpointRequest {
    @Query var key = "value"
}
