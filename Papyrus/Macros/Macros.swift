//
//  File.swift
//  
//
//  Created by Josh Wright on 6/9/23.
//

import Foundation

// MARK: Top Level

@attached(peer, names: arbitrary)
public macro API() = #externalMacro(module: "PapyrusPlugin", type: "APIMacro")

@attached(peer, names: arbitrary)
public macro Mock() = #externalMacro(module: "PapyrusPlugin", type: "MockMacro")

// MARK: Modifiers

@attached(peer, names: arbitrary)
public macro Headers(_ headers: [String: String]) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro JSON(_ converter: JSONConverter = .json) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro URLForm(_ converter: URLFormConverter = .urlForm) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro Converter<C: ContentConverter>(_ converter: C) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro KeyMapping(_ mapping: KeyMapping) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer, names: arbitrary)
public macro Authorization(_ value: AuthorizationHeader) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Methods

@attached(peer, names: arbitrary)
public macro Http(_ path: String, method: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

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

// MARK: Parameters

@attached(accessor)
public macro Header(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Query(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Path(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Field(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(accessor, names: arbitrary)
public macro Body(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")
