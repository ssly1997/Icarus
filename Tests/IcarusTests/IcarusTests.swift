import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import IcarusMacros

let testMacros: [String: Macro.Type] = [
  "icarusCodable": AutoCodableMacro.self,
  "icarusAnnotation": AutoCodableAnnotation.self,
	"icarusMirror": MirrorMacro.self
]

final class IcarusTests: XCTestCase {
  func testAutoCodable() {
    assertMacroExpansion(
      #"""
      struct People { }
      
      @icarusCodable
      struct Student{
        let name: String
        let age: Int
        let address: String?
        let isBoarder: Bool
      }
      """#
      ,
      expandedSource: "",
      macros: testMacros)
  }
  
  func testAnnotation() {
    assertMacroExpansion(
      #"""
      @icarusMirror
      struct Test {
        let a: String
        let b: Int
      }
      //@icarusMirror
      extension Test {}
      """#
      , expandedSource: "",
      macros: testMacros)
  }
	
	func testMirror() {
		assertMacroExpansion(
      #"""
			struct Test {
				let a: String
				let b: Int
			}
			"""#
			, expandedSource: "",
			macros: testMacros)
	}
}
