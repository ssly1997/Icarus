//
//  File.swift
//  
//
//  Created by 李方长 on 2023/6/17.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

enum MirrorError: Swift.Error, CustomStringConvertible {
	case invalidInputType
	
	var description: String {
		"@icarusMirror macro is only applicable to structs or classes"
	}
}

public struct MirrorMacro: MemberMacro, ConformanceMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingConformancesOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
			let type = TypeSyntax(stringLiteral: "IcarusMirror")
			return [(type, nil)]
		}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// get stored properties
		let storedProperties: [VariableDeclSyntax] = try {
			if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
				return classDeclaration.storedProperties()
			} else if let structDeclaration = declaration.as(StructDeclSyntax.self) {
				return structDeclaration.storedProperties()
			} else {
				throw MirrorError.invalidInputType
			}
		}()
		
		// unpacking the property name and type of a stored property
		let arguments = storedProperties.compactMap { property -> (name: String, type: TypeSyntax)? in
			guard let name = property.name, let type = property.type
			else { return nil }
			return (name: name, type: type)
		}
		
		let header = PartialSyntaxNodeString(stringLiteral: "static var mirror: Dictionary<String, Any.Type>")
		let mirrorSyntax = try VariableDeclSyntax(header) {
			ExprSyntax(stringLiteral: "[\n")
			for argument in arguments {
				ExprSyntax(stringLiteral: "\"\(argument.name)\": \(argument.type).self,\n")
			}
			ExprSyntax(stringLiteral: "]")
		}
		
		return [DeclSyntax(mirrorSyntax)]
	}
}
