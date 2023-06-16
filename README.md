# Papyrus

<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/papyrus.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/papyrus/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/papyrus.svg" alt="License"></a>
</p>

Papyrus turns your HTTP API into a Swift `protocol`.

```swift
@API
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(@Path username: String) async throws -> [Repository]
}

struct Repository: Codable { ... }
```

You may then use the generated `GitHubAPI` struct to access the API.

```swift
let provider = Provider(baseURL: "https://api.github.com/")
let github: GitHub = GitHubAPI(provider: provider)
let repos = try await github.getRepositories(username: "alchemy-swift")
```

Annotations on the protocol, functions, and function parameters can be construct your requests.

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

## Requirements

Supports iOS 13+ / macOS 10.15+.

Keep in mind that Papyrus uses Swift macros which require Swift 5.9 / Xcode 14 to compile.

## Installation

You can install Papyrus using the Swift Package Manager.

```swift
dependencies: [
    .package(url: "https://github.com/alchemy-swift/papyrus.git", .upToNextMinor(from: "0.3.0"))
]
```

## Usage

1. [Building a Request](#constructing-a-request)
2. [Handling the Response](#handling-the-response)
3. [Custom Keys](#custom-keys)
4. [Provider Configuration](#provider-configuration)
5. [Testing](#testing)

### Constructing a Request

#### Method & Path

Set the method and path of your request as an attribute on the function. Available annotations are `GET`, `POST`, `PATCH`, `DELETE`, `PUT`, `OPTIONS`, `HEAD`, `TRACE`, and `CONNECT`.

```swift
@DELETE("/transfers/:id")
```

You may set queries directly in the path URL.

```swift
@GET("/transactions?merchant=Apple")
```

#### URL

The `@Path` attribute replaces a parameter in the path. Parameters are denoted with a leading `:`.

```swift
@GET("/repositories/:id")
func getRepository(@Path id: Int) async throws -> [Repository]
```

You may set url queries with the `@Query` parameter.

```swift
@GET("/transactions")
func getTransactions(@Query merchant: String) async throws -> [Transaction]
```

#### Body

The request body can be set using `@Body` on a `Codable` parameter. There can only be one `@Body` in the parameters of a function.

```swift
struct Todo: Codable {
    let name: String
    let isDone: Bool
    let tags: [String]
}

@POST("/todo")
func createTodo(@Body todo: Todo) async throws
```

You can set individual fields in the request body using the `@Field` parameter. These are mutually exclusive with `@Body`.

```swift
@POST("/todo")
func createTodo(@Field name: String, @Field isDone: Bool, @Field tags: [String]) async throws
```

For convenience, a parameter with no name is treated as a `@Field`.

```swift
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

#### Converters

By default, all `@Body` and `@Field` parameters are encoded as `application/json`. You may encode them as `application/x-www-form-urlencoded` using `@URLForm` at the function level.

```swift
@URLForm
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

In addition to functions, you can attribute the entire protocol with `@URLForm` to encode all requests as `@URLForm`.

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

If you'd like to use custom encoding or decoding logic, you may pass an argument to `@JSON` or `@URLForm` the converter attribute.

#### Headers

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
    func updateUser(id: Int, name: String) async throws
}
```

For convenience, there is also an `@Authorization` attribute for setting the `"Authorization"` header.

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

### Handling the Response

Your function return types must conform to `Codable`. They will be decoded from the HTTP response body using the relevant converter. You may also leave the return type empty. In both of these cases, any error that occurs during the request flight will be thrown.

```swift
@GET("/user")
func getUser() async throws -> User
```

To access the raw response instead of automatically decoding a type, you may set the response type to `Response`. Note that in this case, errors that occur during the flight of the request will NOT be thrown so you should check the `Response.error` property before assuming it was successful.

```swift
@GET("/user")
func getUser() async throws -> Response

let res = try await users.getUser()
if res.error == nil {
    print("The response was successful!")
}
```

If you'd like to automatically decode AND access the raw response, you may return a tuple.

```swift
@GET("/user")
func getUser() async throws -> (User, Response)

let (user, res) = try await users.getUser()
print("The response status code was: \(res.statusCode!)")
```

### Custom Keys

If you use two labels for a function parameter, the second one will be inferred as the relevant key.

```swift
@GET("/posts/:postId")
func getPost(id postId: Int) async throws -> Post
```

By default, `@Path`, `@Header`, `@Field`, and `@Header` will be set using the relevant function parameter label. If you'd like a custom key, you can add a parameter to the attribute.

```swift
@GET("/repositories/:id")
func getRepository(@Path("id") repositoryId: Int) async throws -> Repository
```

Often, you'll want to encode request fields and decode response fields using something other than camelCase. Instead of setting the key for each individual attribute, you can use `@KeyMapping` at the function or protocol level.

Note that on requests, this only affects `@Query`, `@Body`, and `@Field` parameters.

```swift
@API
@KeyMapping(.snakeCase)
protocol Todos {
    ...
}
```

### Provider Configuration

Papyrus makes request with Alamofire. You can pass a custom Alamofire session to the provider.

```swift
let customSession: Session = ...
let provider = Provider(baseURL: "https://api.github.com", session: customSession)
let github: GitHub = GitHubAPI(provider: provider)
```

If you'd like to manually run custom build logic before executing any request on a provider, you may use the `modifyRequests()` function.

```swift
let provider = Provider(baseURL: "https://sandbox.plaid.com")
    .modifyRequests { (req: inout RequestBuilder) in
        req.addField("client_id", value: "<client-id>")
        req.addField("secret", value: "<secret>")
    }
let plaid: Plaid = PlaidAPI(provider: provider)
```

You may also add custom request interceptors using `intercept()`. Remember that you'll need to call the second closure parameter if you want the request to continue.

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

If you'd like to decouple your request modifier or interceptor logic from the `Provider`, you can pass instances of the the `RequestModifer` and `Interceptor` protocols when creating a provider.

```swift
let interceptor: Interceptor = ...
let modifier: Interceptor = ...
let provider = Provider(baseURL: "http://localhost:3000", modifiers: [modifier], interceptors: [interceptor])
```

### Testing

APIs defined with Papyrus are simple to mock for tests. Just conform your mock to the protocol. Note that you don't need to include any attributes when conforming to the protocol.

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
        try await getRepositories(username: String).count
    }
}

func testCounting() {
    let mock: GitHub = GitHubMock()
    let service = MyService(github: mock)
    let count = service.countRepositories(of: "joshuawright11")
    XCTAssertEqual(count, 2)
}
```

For your convenience, you may generate a mock by adding the `@Mock` attribute to your protocol. Like `@API`, this creates a new implementation of your protocol. The generated `Mock` type conforms to your protocol and has `mock` functions to easily verify parameters and mock responses.

```swift
@API  // Generates `GitHubAPI`
@Mock // Generates `GitHubMock`
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

## Credits

Papyrus was heavily inspired by [Retrofit](https://github.com/square/retrofit).

## License

Papyrus is released under an MIT license. See [License.md](License.md) for more information.
