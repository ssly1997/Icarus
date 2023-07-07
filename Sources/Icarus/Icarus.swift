// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol IcarusCodable: Codable {
  static var defaultValue: Self { get }
}

public protocol IcarusMirror {
	static var mirror: [String: Any.Type] { get }
}

@attached(conformance)
@attached(member, names: named(`init`), named(defaultValue), named(CodingKeys), named(encode(to:)), named(init(from:)))
public macro icarusCodable() = #externalMacro(module: "IcarusMacros", type: "AutoCodableMacro")

@attached(peer)
public macro icarusAnnotation<T: IcarusCodable>(key: String? = nil, default: T) = #externalMacro(module: "IcarusMacros", type: "AutoCodableAnnotation")
@attached(peer)
public macro icarusAnnotation(key: String) = #externalMacro(module: "IcarusMacros", type: "AutoCodableAnnotation")

@attached(conformance)
@attached(member, names: named(mirror))
public macro icarusMirror() = #externalMacro(module: "IcarusMacros", type: "MirrorMacro")
