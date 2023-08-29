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

public struct AutoCodableMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
      let sendableExtension: DeclSyntax =
            """
            extension \(type.trimmed): IcarusCodable {}
            """
      
      guard let extensionDecl = sendableExtension.as(ExtensionDeclSyntax.self) else {
        return []
      }
      
      return [extensionDecl]
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
      guard let attribute = property.attributes.first(where: { $0.as(AttributeSyntax.self)!.attributeName.description == "icarusAnnotation" })?.as(AttributeSyntax.self),
            let arguments = attribute.arguments?.as(LabeledExprListSyntax.self)
      else { return (name: name, type: type, key: key ?? name, defaultValue: defaultValue) }
      // extracting the key and default values from the annotation and parsing them according to the syntax tree structure.
      arguments.forEach {
        let argument = $0.as(LabeledExprSyntax.self)
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
    let _initDeclSyntax = try InitializerDeclSyntax(
      SyntaxNodeString(stringLiteral: "private init(\(arguments.map { "_\($0.name): \($0.type)" }.joined(separator: ", ")))"),
      bodyBuilder: {
        for argument in arguments {
          ExprSyntax(stringLiteral: "self.\(argument.name) = _\(argument.name)")
        }
      }
    )
    
    // MARK: - defaultValue
    let defaultBody: ExprSyntax = "Self(\(raw: arguments.map { "_\($0.name): \($0.defaultValue ?? $0.type.defaultValueExpression)" }.joined(separator: ",")))"
    let defaultDeclSyntax: VariableDeclSyntax = try VariableDeclSyntax("public static var defaultValue: Self") {
      defaultBody
    }
    
    // MARK: - CodingKeys
    let defineCodingKeys = try EnumDeclSyntax(SyntaxNodeString(stringLiteral: "public enum CodingKeys: String, CodingKey"), membersBuilder: {
      for argument in arguments {
        DeclSyntax(stringLiteral: "case \(argument.key)")
      }
    })
    
    // MARK: - Decoder
    let decoder = try InitializerDeclSyntax(SyntaxNodeString(stringLiteral: "public init(from decoder: Decoder) throws"), bodyBuilder: {
      DeclSyntax(stringLiteral: "let container = try decoder.container(keyedBy: CodingKeys.self)")
      for argument in arguments {
        ExprSyntax(stringLiteral: "\(argument.name) = (try? container.decode(\(argument.type).self, forKey: .\(argument.key))) ?? \(argument.defaultValue ?? argument.type.defaultValueExpression)")
      }
    })
    
    // MARK: - Encoder
    let encoder = try FunctionDeclSyntax(SyntaxNodeString(stringLiteral: "public func encode(to encoder: Encoder) throws"), bodyBuilder: {
      DeclSyntax(stringLiteral: "var container = encoder.container(keyedBy: CodingKeys.self)")
      for argument in arguments {
        ExprSyntax(stringLiteral: "try container.encode(\(argument.name), forKey: .\(argument.key))")
      }
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
