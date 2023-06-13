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

// MARK: Methods

@attached(member, names: arbitrary)
public macro Http(_ path: String, method: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro DELETE2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro GET2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro PATCH2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro POST2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro PUT2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro OPTIONS2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro HEAD2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro TRACE2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(member, names: arbitrary)
public macro CONNECT2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

// MARK: Parameters

@attached(peer, names: arbitrary)
public macro Header2(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Query2(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Path2(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Field2(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Body2(_ key: String? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Default(_ value: Any? = nil) = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")
