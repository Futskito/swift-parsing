import Benchmark
import Foundation
import Parsing

/**
 This benchmark shows how to create a naive JSON parser with combinators.

 It is mostly implemented according to the [spec](https://www.json.org/json-en.html) (we take a
 shortcut and use `Double.parser()`, which behaves accordingly).
 */
let jsonSuite = BenchmarkSuite(name: "JSON") { suite in
  enum JSONValue: Equatable {
    indirect case array([JSONValue])
    case boolean(Bool)
    case null
    case number(Double)
    indirect case object([String: JSONValue])
    case string(String)
  }

  var json: AnyParserPrinter<Substring.UTF8View, JSONValue>!

  let unicode = Prefix(4) {
    (.init(ascii: "0") ... .init(ascii: "9")).contains($0)
      || (.init(ascii: "A") ... .init(ascii: "F")).contains($0)
      || (.init(ascii: "a") ... .init(ascii: "f")).contains($0)
  }
  .map(
    AnyConversion<Substring.UTF8View, String>(
      apply: {
        UInt32(Substring($0), radix: 16)
          .flatMap(UnicodeScalar.init)
          .map(String.init)
      },
      unapply: {
        $0.unicodeScalars.first
          .map(UInt32.init)
          .map { String($0, radix: 16)[...].utf8 }
      }
    )
  )

  let string = Parse {
    "\"".utf8
    Many(into: "") { string, fragment in
      string.append(contentsOf: fragment)
    } iterator: { string in
      CollectionOfOne(string).makeIterator()
    } element: {
      OneOf {
        Prefix(1...) { $0 != .init(ascii: "\"") && $0 != .init(ascii: "\\") }
          .map(.string)

        Parse {
          "\\".utf8

          OneOf {
            "\"".utf8.map(.exactly("\""))
            "\\".utf8.map(.exactly("\\"))
            "/".utf8.map(.exactly("/"))
            "b".utf8.map(.exactly("\u{8}"))
            "f".utf8.map(.exactly("\u{c}"))
            "n".utf8.map(.exactly("\n"))
            "r".utf8.map(.exactly("\r"))
            "t".utf8.map(.exactly("\t"))
            unicode
          }
        }
      }
    } terminator: {
      "\"".utf8
    }
  }

  let object = Parse {
    "{".utf8
    Many(into: [String: JSONValue]()) { object, pair in
      let (name, value) = pair
      object[name] = value
    } iterator: { object in
      object.map { $0 }.makeIterator()
    } element: {
      Whitespace().printing("".utf8)
      string
      Whitespace().printing("".utf8)
      ":".utf8
      Lazy { json! }
    } separator: {
      ",".utf8
    } terminator: {
      "}".utf8
    }
  }

  let array = Parse {
    "[".utf8
    Many {
      Lazy { json! }
    } separator: {
      ",".utf8
    } terminator: {
      "]".utf8
    }
  }

  json = Parse {
    Whitespace().printing("".utf8)
    OneOf {
      object.map(/JSONValue.object)
      array.map(/JSONValue.array)
      string.map(/JSONValue.string)
      Double.parser().map(/JSONValue.number)
      Bool.parser().map(/JSONValue.boolean)
      "null".utf8.map(/JSONValue.null)
    }
    Whitespace().printing("".utf8)
  }
  .eraseToAnyParserPrinter()

  let input = #"""
    {
      "hello": true,
      "goodbye": 42.42,
      "whatever": null,
      "xs": [1, "hello", null, false],
      "ys": {
        "0": 2,
        "1": "goodbye"
      }
    }
    """#
  var jsonOutput: JSONValue!
  suite.benchmark("Parser") {
    var input = input[...].utf8
    jsonOutput = try json.parse(&input)
  } tearDown: {
    precondition(
      jsonOutput
      == .object([
        "hello": .boolean(true),
        "goodbye": .number(42.42),
        "whatever": .null,
        "xs": .array([.number(1), .string("hello"), .null, .boolean(false)]),
        "ys": .object([
          "0": .number(2),
          "1": .string("goodbye"),
        ]),
      ])
    )
    precondition(try! json.parse(json.print(jsonOutput)) == jsonOutput)
  }

  let dataInput = Data(input.utf8)
  var objectOutput: Any!
  suite.benchmark("JSONSerialization") {
    objectOutput = try JSONSerialization.jsonObject(with: dataInput, options: [])
  } tearDown: {
    precondition(
      (objectOutput as! NSDictionary) == [
        "hello": true,
        "goodbye": 42.42,
        "whatever": NSNull(),
        "xs": [1, "hello", nil, false],
        "ys": [
          "0": 2,
          "1": "goodbye",
        ],
      ]
    )
  }
}
