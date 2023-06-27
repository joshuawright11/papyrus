import Foundation

// MARK: Protocol attributes

@attached(peer, names: arbitrary)
public macro API(_ typeName: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "APIMacro")

@attached(peer, names: arbitrary)
public macro Mock(_ typeName: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "MockMacro")

// MARK: Function or Protocol attributes

@attached(peer, names: arbitrary)
public macro Headers(_ headers: [String: String]) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro JSON(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro URLForm(_ encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro Multipart(_ encoder: MultipartEncoder = MultipartEncoder()) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro Converter(encoder: RequestEncoder, decoder: ResponseDecoder) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro KeyMapping(_ mapping: KeyMapping) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro Authorization(_ value: RequestBuilder.AuthorizationHeader) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Function attributes

@attached(peer, names: arbitrary)
public macro HTTP(_ path: String, method: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro DELETE(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro GET(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro PATCH(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro POST(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro PUT(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro OPTIONS(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro HEAD(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro TRACE(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro CONNECT(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Parameter attributes

@attached(accessor)
public macro Header(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Query(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Path(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Field(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Body() = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")
