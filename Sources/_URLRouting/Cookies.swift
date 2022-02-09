// FIXME: Should this be a `Conversion`?

public struct Cookies<Parsers: Parser>: Parser where Parsers.Input == URLRequestData.Fields {
  @usableFromInline
  let cookieParsers: Parsers

  @inlinable
  public init(@ParserBuilder build: () -> Parsers) {
    self.cookieParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URLRequestData) throws -> Parsers.Output {
    guard let cookie = input.headers["cookie"]
    else { throw RoutingError() }

    var fields: Parsers.Input = cookie.reduce(into: [:]) { fields, field in
      guard let cookies = field?.components(separatedBy: "; ")
      else { return }

      for cookie in cookies {
        let pair = cookie.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard pair.count == 2 else { continue }
        fields[String(pair[0]), default: []].append(pair[1])
      }
    }

    return try self.cookieParsers.parse(&fields)
  }
}

extension Cookies: Printer where Parsers: Printer {
  @inlinable
  public func print(_ output: Parsers.Output, to input: inout URLRequestData) rethrows {
    var cookies = URLRequestData.Fields()
    try self.cookieParsers.print(output, to: &cookies)

    input.headers["cookie", default: []].append(
      cookies
        .sorted(by: { $0.key < $1.key })
        .flatMap { name, values in values.map { "\(name)=\($0 ?? "")" } }
        .joined(separator: "; ")[...]
    )
  }
}