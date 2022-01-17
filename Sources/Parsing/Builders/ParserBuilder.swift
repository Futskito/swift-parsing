/// A custom parameter attribute that constructs a sequence of parsers from a block.
@resultBuilder
public enum ParserBuilder {
  @inlinable
  public static func buildBlock<P>(_ parser: P) -> P where P: Parser {
    parser
  }

  @inlinable
  public static func buildFinalResult<P>(_ parser: P) -> P where P: Parser {
    parser
  }

  @inlinable
  public static func buildEither<TrueParser, FalseParser>(
    first parser: TrueParser
  ) -> Conditional<TrueParser, FalseParser> {
    .first(parser)
  }

  @inlinable
  public static func buildEither<TrueParser, FalseParser>(
    second parser: FalseParser
  ) -> Conditional<TrueParser, FalseParser> {
    .second(parser)
  }

  @inlinable
  public static func buildIf<P>(_ parser: P?) -> P? where P: Parser {
    parser
  }

  @inlinable
  public static func buildIf<P>(_ parser: P?) -> Parsers.OptionalVoid<P> {
    .init(upstream: parser)
  }

  @inlinable
  public static func buildLimitedAvailability<P>(_ parser: P?) -> P? where P: Parser {
    parser
  }

  @inlinable
  public static func buildLimitedAvailability<P>(_ parser: P?) -> Parsers.OptionalVoid<P> {
    .init(upstream: parser)
  }
}
