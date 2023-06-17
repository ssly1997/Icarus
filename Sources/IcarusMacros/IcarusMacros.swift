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

@main
struct IcarusPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		AutoCodableMacro.self,
		AutoCodableAnnotation.self,
		MirrorMacro.self
	]
}
