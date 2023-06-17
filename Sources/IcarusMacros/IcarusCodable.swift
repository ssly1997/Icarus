import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

enum CodableError: Swift.Error, CustomStringConvertible {
  case invalidInputType
  
  var description: String {
    "@icarusCodable macro is only applicable to structs or classes"
  }
}

// Annotation macro, unexpanded
public struct AutoCodableAnnotation: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext) throws -> [DeclSyntax] {
      return []
    }
}

public struct AutoCodableMacro: MemberMacro, ConformanceMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingConformancesOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
      let type = TypeSyntax(stringLiteral: "IcarusCodable")
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
        throw CodableError.invalidInputType
      }
    }()
    // unpacking the property name and type of a stored property
    let arguments = storedProperties.compactMap { property -> (name: String, type: TypeSyntax, key: String, defaultValue: String?)? in
      guard let name = property.name, let type = property.type
      else { return nil }
      var key: String?, defaultValue: String?
      // find the icarusAnnotation annotation tag
      guard let attribute = property.attributes?.first(where: { $0.as(AttributeSyntax.self)!.attributeName.description == "icarusAnnotation" })?.as(AttributeSyntax.self),
            let arguments = attribute.argument?.as(TupleExprElementListSyntax.self)
      else { return (name: name, type: type, key: key ?? name, defaultValue: defaultValue) }
      // extracting the key and default values from the annotation and parsing them according to the syntax tree structure.
      arguments.forEach {
        let argument = $0.as(TupleExprElementSyntax.self)
        let expression = argument?.expression.as(StringLiteralExprSyntax.self)
        let segments = expression?.segments.first?.as(StringSegmentSyntax.self)
        let content = segments?.content
        switch argument?.label?.text {
        case "key": key = content?.text
        case "default": defaultValue = argument?.expression.description
        default: break
        }
      }
      // the property name is used as the default key
      return (name: name, type: type, key: key ?? name, defaultValue: defaultValue)
    }
    
    // MARK: - _init
    let _initBody: ExprSyntax = "\(raw: arguments.map { "self.\($0.name) = _\($0.name)" }.joined(separator: "\n"))"
    
    let _initDeclSyntax = try InitializerDeclSyntax(
      PartialSyntaxNodeString(stringLiteral: "private init(\(arguments.map { "_\($0.name): \($0.type)" }.joined(separator: ", ")))"),
      bodyBuilder: {
        _initBody
      }
    )
    
    // MARK: - defaultValue
    let defaultBody: ExprSyntax = "Self(\(raw: arguments.map { "_\($0.name): \($0.defaultValue ?? $0.type.defaultValueExpression)" }.joined(separator: ",")))"
    let defaultDeclSyntax: VariableDeclSyntax = try VariableDeclSyntax("static var defaultValue: Self") {
      defaultBody
    }
    
    // MARK: - CodingKeys
    let defineCodingKeys = try EnumDeclSyntax(PartialSyntaxNodeString(stringLiteral: "public enum CodingKeys: String, CodingKey"), membersBuilder: {
      DeclSyntax(stringLiteral: "\(arguments.map { "case \($0.key)" }.joined(separator: "\n"))")
    })
    
    // MARK: - Decoder
    let decoder = try InitializerDeclSyntax(PartialSyntaxNodeString(stringLiteral: "public init(from decoder: Decoder) throws"), bodyBuilder: {
      DeclSyntax(stringLiteral: "let container = try decoder.container(keyedBy: CodingKeys.self)")
			for argument in arguments {
				ExprSyntax(stringLiteral: "\(argument.name) = (try? container.decode(\(argument.type).self, forKey: .\(argument.key))) ?? \(argument.defaultValue ?? argument.type.defaultValueExpression)")
			}
    })

    // MARK: - Encoder
    let encoder = try FunctionDeclSyntax(PartialSyntaxNodeString(stringLiteral: "public func encode(to encoder: Encoder) throws"), bodyBuilder: {
      let expr: String = "var container = encoder.container(keyedBy: CodingKeys.self)\n\(arguments.map { "try container.encode(\($0.name), forKey: .\($0.key))" }.joined(separator: "\n"))"
			DeclSyntax(stringLiteral: expr)
    })
    
    return [
      DeclSyntax(defineCodingKeys),
      DeclSyntax(decoder),
      DeclSyntax(encoder),
      DeclSyntax(_initDeclSyntax),
      DeclSyntax(defaultDeclSyntax)
    ]
  }
}

extension TypeSyntax {
  var defaultValueExpression: String {
    return "\(self).defaultValue"
  }
}
