# Papyrus 📜

<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/papyrus.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/papyrus/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/papyrus.svg" alt="License"></a>

Papyrus turns your HTTP APIs into type-safe Swift `protocol`s.

```swift
@API
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(@Path username: String) async throws -> [Repository]
}

struct Repository: Codable { ... }
```

Each protocol function represents an endpoint on your API. They can be consumed through an automatically generated type.

```swift
let provider = Provider(baseURL: "https://api.github.com/")
let github: GitHub = GitHubAPI(provider: provider)
let repos = try await github.getRepositories(username: "alchemy-swift")
```

Annotations on the protocol, functions and parameters help construct requests and decode responses.

```swift
@API
@Authorization(.bearer("<my-auth-token>"))
protocol Users {
    @GET("/user")
    func getUser() -> User

    @URLForm
    @POST("/user")
    func createUser(@Field email: String, @Field password: String) -> User
}
```

## Table of Contents

1. [Getting Started](#getting-started)
2. [Defining an Endpoint](#defining-an-endpoint)
3. [Handling the Response](#handling-the-response)
4. [Custom Keys](#custom-keys)
5. [Configuration](#configuration)
6. [Testing](#testing)
7. [Acknowledgements](#acknowledgements)
8. [License](#license)

## Getting Started

### Requirements

Supports iOS 13+ / macOS 10.15+.

Keep in mind that Papyrus uses [macros](https://developer.apple.com/documentation/swift/macros) which require Swift 5.9 / Xcode 15 [(currently in beta)](https://developer.apple.com/xcode/) to compile.

### Installation

You can install Papyrus using the [Swift Package Manager](https://www.swift.org/package-manager/).

```swift
dependencies: [
    .package(url: "https://github.com/alchemy-swift/papyrus.git", .upToNextMinor(from: "0.3.0"))
]
```

## Defining an Endpoint

Individual endpoints are definied by adding functions to your protocol. The function's parameters represent the request content.

### Setting the Method and Path

Set the request method and path as an attribute on the function. Available methods are `GET`, `POST`, `PATCH`, `DELETE`, `PUT`, `OPTIONS`, `HEAD`, `TRACE`, and `CONNECT`. Use `@Http(path:method:)` if you need a custom method.

```swift
@DELETE("/transfers/:id")
```

### Configuring the URL

The `@Path` attribute replaces a named parameter in the path. Parameters are denoted with a leading `:`.

```swift
@GET("/users/:username/repos/:id")
func getRepository(@Path userId: Int, @Path id: Int) async throws -> [Repository]
```

#### Adding Query Parameters

You may set url queries with the `@Query` parameter.

```swift
@GET("/transactions")
func getTransactions(@Query merchant: String) async throws -> [Transaction]
```

You can also set static queries directly in the path string.

```swift
@GET("/transactions?merchant=Apple")
```

### Setting a Body

The request body can be set using `@Body` on a `Codable` parameter. A function can only have one `@Body` parameter.

```swift
struct Todo: Codable {
    let name: String
    let isDone: Bool
    let tags: [String]
}

@POST("/todo")
func createTodo(@Body todo: Todo) async throws
```

Alternatively, you can set individual fields on the body `@Field`. These are mutually exclusive with `@Body`.

```swift
@POST("/todo")
func createTodo(@Field name: String, @Field isDone: Bool, @Field tags: [String]) async throws
```

For convenience, a parameter with no attribute is treated as a `@Field`.

```swift
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

### Encoding the Body

By default, all `@Body` and `@Field` parameters are encoded as `application/json`. You may encode them as `application/x-www-form-urlencoded` using `@URLForm`.

```swift
@URLForm
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

You can also attribute your protocol with `@URLForm` to form encode all request bodies.

```swift
@API
@URLForm
protocol Todos {
    @POST("/todo")
    func createTodo(name: String, isDone: Bool, tags: [String]) async throws

    @PATCH("/todo/:id")
    func updateTodo(@Path id: Int, name: String, isDone: Bool, tags: [String]) async throws
}
```

#### Custom Body Encoders

If you'd like to use a custom JSON or URLForm encoder, you may pass them as arguments to `@JSON` and `@URLForm`.

```swift
extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

@JSON(encoder: .iso8601)
protocol Todos {
    ...
}
```

### Headers

You can set static headers on a request using `@Headers` at the function or protocol scope.

```swift
@Headers(["Cache-Control": "max-age=86400"])
@GET("/user")
func getUser() async throws -> User
```

```swift
@API
@Headers(["X-Client-Version": "1.2.3"])
protocol Users {
    @GET("/user")
    func getUser() async throws -> User

    @PATCH("/user/:id")
    func updateUser(@Path id: Int, name: String) async throws
}
```

For convenience, the `@Authorization` attribute can be used to set a static `"Authorization"` header.

```swift
@Authorization(.basic(username: "joshuawright11", password: "P@ssw0rd"))
protocol Users {
    ...
}
```

A variable header can be set with the `@Header` attribute.

```swift
@GET("/accounts")
func getRepository(@Header customHeader: String) async throws
```

Note that variable headers are automatically mapped to Capital-Kebab-Case. In this case, `Custom-Header`. If you'd like to set a different header key, see the section on [Custom Keys](#custom-keys).

## Handling the Response

The return type of your function represents the response of your endpoint.

### Decoding from the Response

Endpoint functions should return a type that conforms to `Decodable`. It will automatically be decoded from the HTTP response body using JSON by default.

```swift
@GET("/user")
func getUser() async throws -> User
```

### Empty responses

If you don't need to decode something from the response and just want to confirm it was successful, you may leave out the return type.

```swift
@DELETE("/logout")
func logout() async throws
```

Note that if the function return type is Codable or empty, any error that occurs during the request flight, such as an unsuccessful response code, will be thrown.

### Accessing the Raw Response

To just get the raw response you may set the return type to `Response`.

Note that in this case, errors that occur during the flight of the request will NOT be thrown so you should check the `Response.error` property before assuming it was successful.

```swift
@GET("/user")
func getUser() async throws -> Response

let res = try await users.getUser()
if res.error == nil {
    print("The response was successful!")
}
```

If you'd like to automatically decode a type AND access the `Response`, you may return a tuple with both.

```swift
@GET("/user")
func getUser() async throws -> (User, Response)

let (user, res) = try await users.getUser()
print("The response status code was: \(res.statusCode!)")
```

## Custom Keys

If you use two labels for a function parameter, the second one will be inferred as the relevant key.

```swift
@GET("/posts/:postId")
func getPost(@Path id postId: Int) async throws -> Post
```

If you'd like a custom key for `@Path`, `@Header`, `@Field` or `@Query`, you can add a parameter to the attribute.

```swift
@GET("/repositories/:id")
func getRepository(@Path("id") repositoryId: Int) async throws -> Repository
```

### Key Mapping

Often, you'll want to encode request fields and decode response fields using something other than camelCase. Instead of setting a custom key for each individual attribute, you can use `@KeyMapping` at the function or protocol level.

Note that this affects `@Query`, `@Body`, and `@Field` parameters on requests as well as decoding content from the `Response`.

```swift
@API
@KeyMapping(.snakeCase)
protocol Todos {
    ...
}
```

## Configuration

### Alamofire

Under the hood, Papyrus uses [Alamofire](https://github.com/Alamofire/Alamofire) to make requests. If you'd like to use a custom Alamofire `Session` for making requests, pass it in when initializing a `Provider`.

```swift
let customSession: Session = ...
let provider = Provider(baseURL: "https://api.github.com", session: customSession)
let github: GitHub = GitHubAPI(provider: provider)
```

If needbe, you can also access the under-the-hood `Alamofire` and `URLSession` objects on a `Response`.

```swift
let response: Response = ...
let afResponse: DataResponse<Data, AFError> = response.alamofire
let urlResponse: HTTPURLResponse = response.request!
let urlRequest: URLRequest = response.response!
```

### Request Modifiers

If you'd like to manually run custom request build logic before executing any request on a provider, you may use the `modifyRequests()` function.

```swift
let provider = Provider(baseURL: "https://sandbox.plaid.com")
    .modifyRequests { (req: inout RequestBuilder) in
        req.addField("client_id", value: "<client-id>")
        req.addField("secret", value: "<secret>")
    }
let plaid: Plaid = PlaidAPI(provider: provider)
```

### Interceptors

You may also inspect a provider's raw requests and responses by using `intercept()`. Remember that you'll need to call the second closure parameter if you want the request to continue.

```swift
let provider = Provider(baseURL: "http://localhost:3000")
    .intercept { req, next in
        let start = Date()
        let res = try await next(req)
        let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
        // Got a 200 for GET /users after 0.45s
        print("Got a \(res.statusCode!) for \(req.method) \(req.url!.relativePath) after \(elapsedTime)")
        return res
    }
```

If you'd like to decouple your request modifier or interceptor logic from the `Provider`, you can pass instances of the `RequestModifer` and `Interceptor` protocols on provider initialization.

```swift
let interceptor: Interceptor = ...
let modifier: Interceptor = ...
let provider = Provider(baseURL: "http://localhost:3000", modifiers: [modifier], interceptors: [interceptor])
```

## Testing

Because APIs defined with Papyrus are protocols, they're simple to mock in tests; just implement the protocol.

Note that you don't need to include any attributes when conforming to the protocol.

```swift
@API
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(@Path username: String) async throws -> [Repository]
}

struct GitHubMock: GitHub {
    func getRepositories(username: String) async throws -> [Repository] {
        return [
            Repository(name: "papyrus"),
            Repository(name: "alchemy")
        ]
    }
}
```

You can then use your mock during tests when the protocol is required.

```swift
struct CounterService {
    let github: GitHub

    func countRepositories(of username: String) async throws -> Int {
        try await getRepositories(username: username).count
    }
}

func testCounting() {
    let mock: GitHub = GitHubMock()
    let service = MyService(github: mock)
    let count = service.countRepositories(of: "joshuawright11")
    XCTAssertEqual(count, 2)
}
```

### Mocking with @Mock

For your convenience, a mock implementation can be automatically generated with the `@Mock` attribute. Like `@API`, this generates an implementation of your protocol.

In addition to conforming to your protocol, a generated `Mock` type has `mock` functions to easily verify request parameters and mock their responses.

```swift
@API  // Generates `GitHubAPI: GitHub`
@Mock // Generates `GitHubMock: GitHub`
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(@Path username: String) async throws -> [Repository]
}

func testCounting() {
    let mock = GitHubMock()
    mock.mockGetRepositories { username in
        XCTAssertEqual(username, "joshuawright11")
        return [
            Repository(name: "papyrus"),
            Repository(name: "alchemy")
        ]
    }

    let service = MyService(github: mock)
    let count = service.countRepositories(of: "joshuawright11")
    XCTAssertEqual(count, 2)
}
```

## Contribution

👋 Thanks for checking out Papyrus!

If you'd like to contribute please [file an issue](https://github.com/alchemy-swift/papyrus/issues), [open a pull request](https://github.com/alchemy-swift/papyrus/issues) or [start a discussion](https://github.com/alchemy-swift/papyrus/discussions).

## Acknowledgements

Papyrus was heavily inspired by [Retrofit](https://github.com/square/retrofit).

## License

Papyrus is released under an MIT license. See [License.md](License.md) for more information.
