//
//  File.swift
//  
//
//  Created by Josh Wright on 6/9/23.
//

import Foundation

/*
 MARK: - TESTING
 */

@attached(member, names: arbitrary)
public macro GET2(_ path: String) = #externalMacro(module: "PapyrusPlugin", type: "GETMacro")

@attached(peer, names: arbitrary)
public macro API() = #externalMacro(module: "PapyrusPlugin", type: "APIMacro")

// MARK: Parameters

@attached(peer, names: arbitrary)
public macro Header2() = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Query2() = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Path2() = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Field2() = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")

@attached(peer, names: arbitrary)
public macro Body2() = #externalMacro(module: "PapyrusPlugin", type: "HeaderMacro")
