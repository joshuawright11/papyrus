# Papyrus

## INTRODUCTION

Papyrus turns your HTTP API into a Swift `protocol`.

```swift
@API
protocol GitHub {
@GET("/users/:username/repos")
func getRepositories(@Path username: String) async throws -> [Repository]
}

struct Repository: Codable {}
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

## Constructing a Request

### Method & Path

Set the method and path of your request as an attribute on the function. Available annotations are `GET`, `POST`, `PATCH`, `DELETE`, `PUT`, `OPTIONS`, `HEAD`, `TRACE`, and `CONNECT`.

```swift
@DELETE("/transfers/:id")
```

You may set queries directly in the path URL.

```swift
@GET("/transactions?merchant=Apple")
```

### URL

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

### Body

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

## Handling the Response

## Misc

By default, `@Path`, `@Header`, `@Field`, and `@Header` will be set using the label of their function parameter. If you'd like a custom key, you can add a parameter to the attribute.

```swift
@GET("/repositories/:id")
func getRepository(@Path("id") _ repositoryId: Int)
```

## Provider

## Testing
