import Foundation

// MARK: Protocol attributes

@attached(peer, names: suffixed(API))
public macro API(_ typeName: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "APIMacro")

@attached(peer, names: suffixed(Mock))
public macro Mock(_ typeName: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "MockMacro")

// MARK: Function or Protocol attributes

@attached(peer)
public macro Headers(_ headers: [String: String]) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro JSON(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro URLForm(_ encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro Multipart(_ encoder: MultipartEncoder = MultipartEncoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro Converter(encoder: RequestEncoder, decoder: ResponseDecoder) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro KeyMapping(_ mapping: KeyMapping) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro Authorization(_ value: RequestBuilder.AuthorizationHeader) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Function attributes

@attached(peer)
public macro HTTP(_ path: String, method: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro DELETE(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro GET(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro PATCH(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro POST(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro PUT(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro OPTIONS(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro HEAD(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro TRACE(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro CONNECT(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Parameter attributes

@attached(accessor)
public macro Header(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor)
public macro Query(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor)
public macro Path(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor)
public macro Field(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor)
public macro Body() = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")
