import Foundation
import Papyrus

final class TestAPI: API {
    @URLForm
    @HeaderWrapper
    @HeaderWrapper(name: "one", value: "1")
    @HeaderWrapper(name: "two", value: "2")
    @HeaderWrapper(name: "three", value: "3")
    @HeaderWrapper(name: "four", value: "4")
    @HeaderWrapper(name: "five", value: "5")
    @PUT("/body")
    var stacked = Endpoint<Empty, Empty>()
    
    @CUSTOM(method: "FOO", "/foo")
    var custom = Endpoint<Empty, Empty>()
}
