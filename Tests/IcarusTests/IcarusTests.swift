import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import IcarusMacros

let testMacros: [String: Macro.Type] = [
  "icarusCodable": AutoCodableMacro.self,
  "icarusAnnotation": AutoCodableAnnotation.self
]

final class IcarusTests: XCTestCase {
  func testAutoCodable() {
    assertMacroExpansion(
      #"""
      struct People { }
      
      @icarusCodable
      struct Test{
        let name: String
        @icarusAnnotation(key: "key_age", default: 12)
        let age: Int
        @icarusAnnotation(default: "asd")
        let address: String
      }
      """#
      ,
      expandedSource: "",
      macros: testMacros)
  }
  
  func testAnnotation() {
    assertMacroExpansion(
      #"""
      struct Test{
        @icarusAnnotation(default: "hhh")
        let a: String
        @icarusAnnotation(key: "key_b", default: 123)
        let b: Int
      }
      """#
      , expandedSource: "",
      macros: testMacros)
  }
}
