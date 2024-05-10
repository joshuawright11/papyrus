import MacroTesting
@testable
import PapyrusPlugin
import XCTest

final class APIMacroTests: XCTestCase {
    func testRequireProtocol() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            struct MyService {
            }
            """
        } diagnostics: {
            """
            @API
            ┬───
            ╰─ 🛑 @API can only be applied to protocols.
            struct MyService {
            }
            """
        }
    }

    func testVoidReturn() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            protocol Foo {
                @GET("/bar")
                func bar() async throws

                @GET("/baz")
                func baz() async throws -> Void
            }
            """
        } expansion: {
            """
            protocol Foo {
                @GET("/bar")
                func bar() async throws

                @GET("/baz")
                func baz() async throws -> Void
            }

            struct FooAPI: Foo {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func bar() async throws {
                    var req = builder(method: "GET", path: "/bar")
                    try await provider.request(&req).validate()
                }

                func baz() async throws -> Void {
                    var req = builder(method: "GET", path: "/baz")
                    try await provider.request(&req).validate()
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }

    func testJSONDecoderOnly() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            @JSON(decoder: JSONDecoder())
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: String) async throws -> String
            }
            """
        } expansion: {
            """
            @JSON(decoder: JSONDecoder())
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: String) async throws -> String
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func myQuery(id userId: String) async throws -> String {
                    var req = builder(method: "GET", path: "some/path")
                    req.addQuery("userId", value: userId)
                    let res = try await provider.request(&req)
                    try res.validate()
                    return try res.decode(String.self, using: req.responseDecoder)
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    var req = provider.newBuilder(method: method, path: path)
                    req.requestEncoder = .json(JSONEncoder())
                    req.responseDecoder = .json(JSONDecoder())
                    return req
                }
            }
            """
        }
    }

    func testGetInfersQuery() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: String) async throws -> String
            }
            """
        } expansion: {
            """
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: String) async throws -> String
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func myQuery(id userId: String) async throws -> String {
                    var req = builder(method: "GET", path: "some/path")
                    req.addQuery("userId", value: userId)
                    let res = try await provider.request(&req)
                    try res.validate()
                    return try res.decode(String.self, using: req.responseDecoder)
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }

    func testGetExplicitField() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: Field<Int>) async throws -> String
            }
            """
        } expansion: {
            """
            protocol MyService {
                @GET("some/path")
                func myQuery(id userId: Field<Int>) async throws -> String
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func myQuery(id userId: Field<Int>) async throws -> String {
                    var req = builder(method: "GET", path: "some/path")
                    req.addField("userId", value: userId)
                    let res = try await provider.request(&req)
                    try res.validate()
                    return try res.decode(String.self, using: req.responseDecoder)
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }

    func testQuery_GET() {
        assertMacro(["API": APIMacro.self]) {
            """
            enum Since: String, Codable {
                case one, two, three
            }
            @API
            protocol MyService {
                @GET("users/:userId")
                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String
            }
            """
        } expansion: {
            """
            enum Since: String, Codable {
                case one, two, three
            }
            protocol MyService {
                @GET("users/:userId")
                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String {
                    var req = builder(method: "GET", path: "users/:userId")
                    req.addParameter("userId", value: userId)
                    req.addQuery("since", value: since)
                    let res = try await provider.request(&req)
                    try res.validate()
                    return try res.decode(String.self, using: req.responseDecoder)
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }

    func testQuery_POST() {
        assertMacro(["API": APIMacro.self]) {
            """
            enum Since: String, Codable {
                case one, two, three
            }

            @API
            protocol MyService {
                @POST("users/:userId")
                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String
            }
            """
        } expansion: {
            """
            enum Since: String, Codable {
                case one, two, three
            }
            protocol MyService {
                @POST("users/:userId")
                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func getUser(userId: Path<String>, since: Query<Since>) async throws -> String {
                    var req = builder(method: "POST", path: "users/:userId")
                    req.addParameter("userId", value: userId)
                    req.addQuery("since", value: since)
                    let res = try await provider.request(&req)
                    try res.validate()
                    return try res.decode(String.self, using: req.responseDecoder)
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }

    func testJSON() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            @KeyMapping(.snakeCase)
            @JSON(encoder: .foo, decoder: .bar)
            protocol MyService {
                @POST("users")
                func getUser() async throws
            }
            """
        } expansion: {
            """
            @KeyMapping(.snakeCase)
            @JSON(encoder: .foo, decoder: .bar)
            protocol MyService {
                @POST("users")
                func getUser() async throws
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func getUser() async throws {
                    var req = builder(method: "POST", path: "users")
                    try await provider.request(&req).validate()
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    var req = provider.newBuilder(method: method, path: path)
                    req.keyMapping = .snakeCase
                    req.requestEncoder = .json(.foo)
                    req.responseDecoder = .json(.bar)
                    return req
                }
            }
            """
        }
    }

    func testJSONMultiline() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            @KeyMapping(.snakeCase)
            @JSON(
                encoder: .foo,
                decoder: .bar
            )
            protocol MyService {
                @POST("users")
                func getUser() async throws
            }
            """
        } expansion: {
            """
            @KeyMapping(.snakeCase)
            @JSON(
                encoder: .foo,
                decoder: .bar
            )
            protocol MyService {
                @POST("users")
                func getUser() async throws
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func getUser() async throws {
                    var req = builder(method: "POST", path: "users")
                    try await provider.request(&req).validate()
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    var req = provider.newBuilder(method: method, path: path)
                    req.keyMapping = .snakeCase
                    req.requestEncoder = .json(.foo)
                    req.responseDecoder = .json(.bar)
                    return req
                }
            }
            """
        }
    }

    func testMultiplePaths() {
        assertMacro(["API": APIMacro.self]) {
            """
            @API
            protocol MyService {
                @GET("users/:foo/:b_ar/{baz}/{z_ip}")
                func getUser(foo: String, bAr: String, baz: Int, zIp: Int) async throws
            }
            """
        } expansion: {
            """
            protocol MyService {
                @GET("users/:foo/:b_ar/{baz}/{z_ip}")
                func getUser(foo: String, bAr: String, baz: Int, zIp: Int) async throws
            }

            struct MyServiceAPI: MyService {
                private let provider: PapyrusCore.Provider

                init(provider: PapyrusCore.Provider) {
                    self.provider = provider
                }

                func getUser(foo: String, bAr: String, baz: Int, zIp: Int) async throws {
                    var req = builder(method: "GET", path: "users/:foo/:b_ar/{baz}/{z_ip}")
                    req.addParameter("foo", value: foo)
                    req.addParameter("b_ar", value: bAr)
                    req.addParameter("baz", value: baz)
                    req.addParameter("z_ip", value: zIp)
                    try await provider.request(&req).validate()
                }

                private func builder(method: String, path: String) -> RequestBuilder {
                    provider.newBuilder(method: method, path: path)
                }
            }
            """
        }
    }
}
