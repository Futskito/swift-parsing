import Parsing
import XCTest

final class OneOfBuilderTests: XCTestCase {
  func testBuildIf() {
    enum Role {
      case admin
      case guest
      case member
    }

    var parseAdmins = false
    var parser = OneOf {
      if parseAdmins {
        "admin".map { Role.admin }
      }

      "guest".map { Role.guest }
      "member".map { Role.member }
    }

    (
      parseAdmins
      ? "admin".map { Role.admin }.eraseToAnyParser()
      : Fail().eraseToAnyParser()
    )
      .orElse("guest".map { Role.guest })
      .orElse("member".map { Role.member })

    (
      parseAdmins
      ? Conditional.first("admin".map { Role.admin })
      : .second(Fail())
    )
      .orElse("guest".map { Role.guest })
      .orElse("member".map { Role.member })

    XCTAssertEqual(.guest, parser.parse("guest"))
    XCTAssertEqual(nil, parser.parse("admin"))

    parseAdmins = true
    parser = OneOf {
      if parseAdmins {
        "admin".map { Role.admin }
      }

      "guest".map { Role.guest }
      "member".map { Role.member }
    }
    XCTAssertEqual(.guest, parser.parse("guest"))
    XCTAssertEqual(.admin, parser.parse("admin"))
  }
}