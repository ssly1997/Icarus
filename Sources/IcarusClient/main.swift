import Icarus
import Foundation

@icarusCodable
struct Test{
  let name: String
  @icarusAnnotation(key: "new_age", default: 99)
  let age: Int
	@icarusAnnotation(key: "new_add", default: "aa")
  let address: String
  let optional: String?
  let array: [String]
  let dic: [String: Int?]
  let people: People
}

@icarusCodable
struct Generic<T: IcarusCodable> {
  let value: T
  let a: Int
}

// key不存在 解析
let dic: [String: Any] = [:]

do {
  let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
  let value = try JSONDecoder().decode(Generic<Test>.self, from: jsonData)
//  print(value)
} catch {
  print("Error: \(error)")
}

enum Sex: Codable {
	case male
	case female
}

extension Sex: IcarusCodable {
	static var defaultValue: Sex { .female }
}

let a = 99

@icarusCodable
struct People{
//  @icarusAnnotation(default: "aaaad")
  let name: String
  @icarusAnnotation(key: "new_age", default: a + 1)
  let age: Int
//	@icarusAnnotation(default: Sex.female)
	let sex: Sex
}

let peopleDic: [String: Any] = ["name": "ldc", "age": false]

do {
  let value: People = try decode(peopleDic)
//  print(value)
} catch {
  print("Error: \(error)")
}

extension Dictionary: IcarusCodable where Value: IcarusCodable, Key: IcarusCodable {
  public static var defaultValue: Dictionary<Key, Value> { [:] }
}

extension Array: IcarusCodable where Element: IcarusCodable {
  public static var defaultValue: Array<Element> { [] }
}

extension Optional: IcarusCodable where Wrapped: IcarusCodable {
  public static var defaultValue: Optional<Wrapped> { nil }
}

extension Int: IcarusCodable {
  public static var defaultValue: Int { 0 }
}

extension String: IcarusCodable {
  public static var defaultValue: String { "" }
}

func decode<T: Codable>(_ dic: [String: Any]) throws -> T {
  let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
  return try JSONDecoder().decode(T.self, from: jsonData)
}

@icarusMirror
struct MirrorTest {
	let name: String
	let age: Int
	let people: People
	let optional: Int??
}

print(MirrorTest.mirror)
