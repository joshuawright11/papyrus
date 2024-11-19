# 📜 Papyrus

<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift Version"></a>
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-green.svg" alt="Swift Version"></a>
<a href="https://github.com/kevin-kp/papyrus/releases"><img src="https://img.shields.io/github/release/joshuawright11/papyrus.svg" alt="Latest Release"></a>
<a href="https://github.com/kevin-kp/papyrus/blob/main/LICENSE"><img src="https://img.shields.io/github/license/joshuawright11/papyrus.svg" alt="License"></a>

Papyrus is a type-safe HTTP client for Swift.

It reduces your network boilerplate by turning turns your APIs into clean and concise Swift protocols.

It's [Retrofit](https://github.com/square/retrofit) for Swift!

```swift
@API
@Authorization(.bearer("<my-auth-token>"))
protocol Users {
    @GET("/user")
    func getUser() async throws -> User

    @POST("/user")
    func createUser(email: String, password: String) async throws -> User

    @GET("/users/:username/todos")
    func getTodos(username: String) async throws -> [Todo]
}
```

```swift
let provider = Provider(baseURL: "https://api.example.com/")
let users: Users = UsersAPI(provider: provider)
let todos = try await users.getTodos(username: "joshuawright11")
```

Each endpoint of your API is represented as function on the protocol.

Annotations on the protocol, functions, and parameters help construct requests and decode responses.

## Table of Contents

0. [Features](#features)
1. [Getting Started](#getting-started)
2. [Requests](#requests)
3. [Responses](#responses)
4. [Advanced](#advanced)
5. [Testing](#testing)
6. [Acknowledgements](#acknowledgements)
7. [License](#license)

## Features

-   [x] Turn REST APIs into Swift Protocols
-   [x] `async`/`await` _or_ [Callback APIs](#callback-apis)
-   [x] JSON, URLForm and Multipart Encoding Support
-   [x] Automatic Key Mapping
-   [x] Sensible Parameter Defaults Based on HTTP Verb
-   [x] Automatically Decode Responses with `Codable`
-   [x] Custom Interceptors & Request Builders
-   [x] Advanced Error Handling
-   [x] Automatic Mocks for Testing
-   [x] Powered by `URLSession` or [Alamofire](https://github.com/Alamofire/Alamofire) Out of the Box
-   [x] Linux / Swift on Server Support Powered by [async-http-client](https://github.com/swift-server/async-http-client)

## Getting Started

### Requirements

Supports iOS 13+ / macOS 10.15+.

Keep in mind that Papyrus uses [macros](https://developer.apple.com/documentation/swift/macros) which require Swift 5.9 / Xcode 15 to compile.

### Installation

Install Papyrus using the [Swift Package Manager](https://www.swift.org/package-manager/), choosing a backing networking library from below.

<details>
  <summary>URLSession</summary>

### URLSession

Out of the box, Papyrus is powered by `URLSession`.

```swift
.package(url: "https://github.com/joshuawright11/papyrus.git", from: "0.6.0")
```

```swift
.product(name: "Papyrus", package: "papyrus")
```

</details>

<details>
  <summary>Alamofire</summary>

### Alamofire

If you'd prefer to use [Alamofire](https://github.com/Alamofire/Alamofire), use the `PapyrusAlamofire` product.

```swift
.package(url: "https://github.com/joshuawright11/papyrus.git", from: "0.6.0")
```

```swift
.product(name: "PapyrusAlamofire", package: "papyrus")
```

</details>

<details>
  <summary>AsyncHTTPClient (Linux)</summary>

### AsyncHTTPClient (Linux)

If you're using Linux / Swift on Server, use the separate package [PapyrusAsyncHTTPClient](https://github.com/joshuawright11/papyrus-async-http-client). It's driven by the [swift-nio](https://github.com/apple/swift-nio) backed [async-http-client](https://github.com/swift-server/async-http-client).

```swift
.package(url: "https://github.com/joshuawright11/papyrus-async-http-client.git", from: "0.2.0")
```

```swift
.product(name: "PapyrusAsyncHTTPClient", package: "papyrus-async-http-client")
```

</details>

## Requests

You'll represent each of your REST APIs with a _protocol_.

Individual endpoints are represented by a _function_ on that protocol.

The function's _parameters_ help Papyrus build the request and the _return type_ indicates how to handle the response.

### Method and Path

Set the request method and path as an attribute on the function. Available methods are `GET`, `POST`, `PATCH`, `DELETE`, `PUT`, `OPTIONS`, `HEAD`, `TRACE`, and `CONNECT`. Use `@HTTP(_ path:method:)` if you need a custom method.

```swift
@POST("/accounts/transfers")
```

### Path Parameters

Parameters in the path, marked with a leading `:`, will be automatically replaced by matching parameters in the function.

```swift
@GET("/users/:username/repos/:id")
func getRepository(username: String, id: Int) async throws -> [Repository]
```

#### Query Parameters

Function parameters on a `@GET`, `@HEAD`, or `@DELETE` request are inferred to be a query.

```swift
@GET("/transactions") // GET /transactions?merchant=...
func getTransactions(merchant: String) async throws -> [Transaction]
```

If you need to add query paramters to requests of other HTTP Verbs, mark the parameter with `Query<T>`.

```swift
@POST("/cards") // POST /cards?username=...
func fetchCards(username: Query<String>) async throws -> [Card]
```

### Static Query Parameters

Static queries can be set directly in the path string.

```swift
@GET("/transactions?merchant=Apple")
```

### Headers

A variable request header can be set with the `Header<T>` type. Its key will be automatically mapped to Capital-Kebab-Case. e.g. `Custom-Header` in the following endpoint.

```swift
@GET("/accounts")
func getRepository(customHeader: Header<String>) async throws
```

#### Static Headers

You can set static headers on a request using `@Headers` at the function or protocol scope.

```swift
@Headers(["Cache-Control": "max-age=86400"])
@GET("/user")
func getUser() async throws -> User
```

```swift
@API
@Headers(["X-Client-Version": "1.2.3"])
protocol Users { ... }
```

#### Authorization Header

For convenience, the `@Authorization` attribute can be used to set a static `"Authorization"` header.

```swift
@Authorization(.basic(username: "joshuawright11", password: "P@ssw0rd"))
protocol Users {
    ...
}
```

### Body

Function parameters on a request that _isn't_ a `@GET`, `@HEAD`, or `@DELETE` are inferred to be a field in the body.

```swift
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

If you need to explicitly mark a parameter as a body field, use `Field<T>`.

```swift
@POST("/todo")
func createTodo(name: Field<String>, isDone: Field<Bool>, tags: Field<[String]>) async throws
```

#### `Body<T>`

Aternatively, the entire request body can be set using `Body<T>`. An endpoint can only have one `Body<T>` parameter and it is mutually exclusive with `Field<T>`.

```swift
struct Todo: Codable {
    let name: String
    let isDone: Bool
    let tags: [String]
}

@POST("/todo")
func createTodo(todo: Body<Todo>) async throws
```

#### Body Encoding

By default, all `Body` and `Field` parameters are encoded as `application/json`. You can encode with a custom `JSONEncoder` using the `@JSON` attribute.

```swift
extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

@JSON(encoder: .iso8601)
@POST("/user")
func createUser(username: String, password: String) async throws
```

##### URLForm

You may encode body parameters as `application/x-www-form-urlencoded` using `@URLForm`.

```swift
@URLForm
@POST("/todo")
func createTodo(name: String, isDone: Bool, tags: [String]) async throws
```

##### Multipart

You can also encode body parameters as `multipart/form-data` using `@Multipart`. If you do, all body parameters must be of type `Part`.

```swift
@Multipart
@POST("/attachments")
func uploadAttachments(file1: Part, file2: Part) async throws
```

##### Global Encoding

You can attribute your protocol with an encoding attribute to encode all requests as such.

```swift
@API
@URLForm
protocol Todos {
    @POST("/todo")
    func createTodo(name: String, isDone: Bool, tags: [String]) async throws

    @PATCH("/todo/:id")
    func updateTodo(id: Int, name: String, isDone: Bool, tags: [String]) async throws
}
```

##### Custom Body Encoders

If you'd like to use a custom encoder, you may pass them as arguments to `@JSON`, `@URLForm` and `@Multipart`.

```swift
extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

@JSON(encoder: .iso8601)
protocol Todos { ... }
```

## Responses

The return type of your function tells Papyrus how to handle the endpoint response.

### `Decodable`

If your function returns a type conforming to `Decodable`, Papyrus will automatically decode it from the response body using `JSONDecoder`.

```swift
@GET("/user")
func getUser() async throws -> User
```

### `Data`

If you only need a response's raw body bytes, you can just return `Data?` or `Data` from your function.

```swift
@GET("/bytes")
func getBytes() async throws -> Data?

@GET("/image")
func getImage() async throws -> Data // this will throw an error if `GET /image` returns an empty body
```

### `Void`

If you just want to confirm the response was successful and don't need to access the body, you may leave out the return type.

```swift
@DELETE("/logout")
func logout() async throws
```

### `Response`

If you want the raw response data, e.g. to access headers, set the return type to `Response`.

```swift
@GET("/user")
func getUser() async throws -> Response

let res = try await users.getUser()
print("The response had headers \(res.headers)")
```

If you'd like to automatically decode a type AND access the `Response`, you may return a tuple with both.

```swift
@GET("/user")
func getUser() async throws -> (User, Response)

let (user, res) = try await users.getUser()
print("The response status code was: \(res.statusCode!)")
```

### Error Handling

If any errors occur while making a request, a `PapyrusError` will be thrown. Use it to access any `Request` and `Response` associated with the error.

```swift
@GET("/user")
func getUser() async throws -> User

do {
    let user = try await users.getUser()
} catch {
    if let error = error as? PapyrusError {
        print("Error making request \(error.request): \(error.message). Response was: \(error.response)")
    }
}
```

## Advanced

### Parameter Labels

If you use two labels for a function parameter, the second one will be inferred as the relevant key.

```swift
@GET("/posts/:postId")
func getPost(id postId: Int) async throws -> Post
```

### Key Mapping

Often, you'll want to encode request fields and decode response fields using something other than camelCase. Instead of setting a custom key for each individual attribute, you can use `@KeyMapping` at the function or protocol level.

Note that this affects `Query`, `Body`, and `Field` parameters on requests as well as decoding content from the `Response`.

```swift
@API
@KeyMapping(.snakeCase)
protocol Todos {
    ...
}
```

### Access Control

When you use `@API` or [`@Mock`](#mocking-with-mock), Papyrus will generate an implementation named `<protocol>API` or `<protocol>Mock` respectively. The [access level](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/) will match the access level of the protocol.

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

You may also inspect a `Provider`'s raw `Request`s and `Response`s using `intercept()`. Make sure to call the second closure parameter if you want the request to continue.

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

### `RequestModifer` & `Interceptor` protocols

You can isolate request modifier and interceptor logic to a specific type for use across multiple `Provider`s using the `RequestModifer` and `Interceptor` protocols. Pass them to a `Provider`'s initializer.

```swift
struct MyRequestModifier: RequestModifier { ... }
struct MyInterceptor: Interceptor { ... }
let provider = Provider(baseURL: "http://localhost:3000", modifiers: [MyRequestModifier()], interceptors: [MyInterceptor()])
```

### Callback APIs

[Swift concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) is the modern way of running asynchronous code in Swift.

If you haven't yet migrated to Swift concurrency and need access to a callback based API, you can pass an `@escaping` completion handler as the last argument in your endpoint functions.

The function must have no return type and the closure must have a single argument of type `Result<T: Codable, Error>`, `Result<Void, Error>`, or `Response` argument.

```swift
// equivalent to `func getUser() async throws -> User`
@GET("/user")
func getUser(callback: @escaping (Result<User, Error>) -> Void)

// equivalent to `func createUser(email: String, password: String) async throws`
@POST("/user")
func createUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)

// equivalent to `func getResponse() async throws -> Response`
@GET("/response")
func getResponse(completion: @escaping (Response) -> Void)
```

## Testing

Because APIs defined with Papyrus are protocols, they're simple to mock in tests; just implement the protocol.

If you use `Path<T>`, `Header<T>`, `Field<T>`, or `Body<T>` types, you don't need to include them in your protocol conformance. They are just typealiases used to hint Papyrus how to use the parameter.

```swift
@API
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(username: String) async throws -> [Repository]
}

struct GitHubMock: GitHub {
    func getRepositories(username: String) async throws -> [Repository] {
        return [
            Repository(name: "papyrus"),
            Repository(name: "alchemy"),
            Repository(name: "fusion"),
        ]
    }
}
```

You can then use your mock during tests when the protocol is required.

```swift
func testCounting() {
    let mock: GitHub = GitHubMock()
    let service = MyService(github: mock)
    let count = service.countRepositories(of: "joshuawright11")
    XCTAssertEqual(count, 3)
}
```

### @Mock

For convenience, you can leverage macros to automatically generated mocks using `@Mock`. Like `@API`, this generates an implementation of your protocol.

The generated `Mock` type has `mock` functions to easily verify request parameters and mock responses.

```swift
@API  // Generates `GitHubAPI: GitHub`
@Mock // Generates `GitHubMock: GitHub`
protocol GitHub {
    @GET("/users/:username/repos")
    func getRepositories(username: String) async throws -> [Repository]
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

If you'd like to contribute please [file an issue](https://github.com/joshuawright11/papyrus/issues), [open a pull request](https://github.com/joshuawright11/papyrus/pulls) or [start a discussion](https://github.com/joshuawright11/papyrus/discussions).

## Acknowledgements

Papyrus was heavily inspired by [Retrofit](https://github.com/square/retrofit).

## License

Papyrus is released under an MIT license. See [License.md](License.md) for more information.
