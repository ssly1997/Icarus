# Icarus
封装了一些功能性的宏
## IcarusCodable
解决Codable难以设置默认值的问题，支持自定义CodingKeys、自定义默认值。

### 设置基本类型 `默认的默认值`
为常见基本类型实现 `IcarusCoable` 协议:
`默认的默认值`是指没有在注解中特地声明自定义默认值时，宏所获取的默认值。它默认从IcarusCodable协议中的 defaultValue 中取值，所以在使用时，需要提前为所有的基本类型实现此协议，声明这些 `默认的默认值`。
你可以在你的项目中自由的定义这些默认的默认值。
```
import Icarus

extension Int: IcarusCodable {
  public static var defaultValue: Int { 0 }
}

extension String: IcarusCodable {
  public static var defaultValue: String { "" }
}

extension Double: IcarusCodable {
  public static var defaultValue: Double { 0.0 }
}

extension Bool: IcarusCodable {
  public static var defaultValue: Bool { false }
}

extension Optional: IcarusCodable where Wrapped: IcarusCodable {
  public static var defaultValue: Optional<Wrapped> { .none }
}

extension Dictionary: IcarusCodable where Value: IcarusCodable, Key: IcarusCodable {
  public static var defaultValue: Dictionary<Key, Value> { [:] }
}

extension Array: IcarusCodable where Element: IcarusCodable {
  public static var defaultValue: Array<Element> { [] }
}

```

### 为自定义类型添加宏（仅支持 struct/class)
在定义之前添加 `@icarusCodable` 即可为类型自动遵循并实现 `IcarusCoable` 协议。
通过注解宏 `@icarusAnnotation` 可以为属性设置 CodingKey 和 自定义默认值。
```
@icarusCodable
struct Student {
  @icarusAnnotation(key: "new_name")
  let name: String
  @icarusAnnotation(default: 100)
  let age: Int
  @icarusAnnotation(key: "new_address", default: "abc")
  let address: String?
  @icarusAnnotation(default: true)
  let isBoarder: Bool
// === 宏展开开始 ===
public enum CodingKeys: String, CodingKey {
    case new_name
    case age
    case new_address
    case isBoarder
}

public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = (try? container.decode(String.self, forKey: .new_name)) ?? String.defaultValue
    age = (try? container.decode(Int.self, forKey: .age)) ?? 100
    address = (try? container.decode(String?.self, forKey: .new_address)) ?? "abc"
    isBoarder = (try? container.decode(Bool.self, forKey: .isBoarder)) ?? true
}

public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .new_name)
    try container.encode(age, forKey: .age)
    try container.encode(address, forKey: .new_address)
    try container.encode(isBoarder, forKey: .isBoarder)
}

private init(_name: String, _age: Int, _address: String?, _isBoarder: Bool) {
    self.name = _name
    self.age = _age
    self.address = _address
    self.isBoarder = _isBoarder
}

public static var defaultValue: Self {
    Self (_name: String.defaultValue, _age: 100, _address: "abc", _isBoarder: true)
}
// === 宏展开结束 ===
}
// === 宏展开开始 ===
extension Student : IcarusCodable  {}
// === 宏展开结束 ===
```
### 类型中包含自定义类型
只要包含的自定义类型也是 IcarusCodable 类型，那么宏就可以正常展开，否则，你需要手动为此类型实现 IcarusCodable 协议。
```
@icarusCodable
struct Address {
  let country: String
  let province: String
  let city: String
}

@icarusCodable
struct Student {
  @icarusAnnotation(key: "new_name")
  let name: String
  @icarusAnnotation(default: 100)
  let age: Int
  let address: Address
  @icarusAnnotation(default: true)
  let isBoarder: Bool
}
```

### 关于枚举
宏不适用于枚举类型，但如果自定义类型中包含枚举类型，请使此枚举遵循并手动实现 IcarusCodable:
```
enum Sex: IcarusCodable {
  case male
  case female
  
  static var defaultValue: Sex { .male }
}

@icarusCodable
struct Student {
  @icarusAnnotation(key: "new_name")
  let name: String
  @icarusAnnotation(default: 100)
  let age: Int
  let address: Address
  @icarusAnnotation(default: true)
  let isBoarder: Bool
  let sex: Sex
}
```
