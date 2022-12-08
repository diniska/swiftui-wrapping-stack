import XCTest
@testable import WrappingStack

final class LinesTests: XCTestCase {
    func testSingleLargeElementIsPutOnTheFirstLine() {
        let lines = Lines(elements: [200], spacing: 10)
        let split = lines.split(lengthLimit: 100)
        XCTAssertEqual(split, [0 ..< 1])
    }
    
    func testMovesElementToSecondLineWhenFirstLineIsTakenBySingleElement() {
        let lines = Lines(elements: [200, 5], spacing: 10)
        let split = lines.split(lengthLimit: 100)
        XCTAssertEqual(split, [0 ..< 1, 1 ..< 2])
    }
    
    func testFitsTwoElementOnASingleLineWithoutSpacing() {
        let lines = Lines(elements: [5, 5])
        let split = lines.split(lengthLimit: 10)
        XCTAssertEqual(split, [0 ..< 2])
    }
    
    func testDoesNotFitsTwoElementOnASingleLineWhenOverflowsDueToSpacing() {
        let lines = Lines(elements: [5, 5], spacing: 1)
        let split = lines.split(lengthLimit: 10)
        XCTAssertEqual(split, [0 ..< 1, 1 ..< 2])
    }
    
    func testDoesNotAddSpacingAtTheBeginningOfALine() {
        let lines = Lines(elements: [5, 5], spacing: 10)
        let split = lines.split(lengthLimit: 5)
        XCTAssertEqual(split, [0 ..< 1, 1 ..< 2])
    }
    
    func testDoesNotMoveElementToAThirdLineWhenItsASingleElementOnTheSecond() {
        let lines = Lines(elements: [100, 100])
        let split = lines.split(lengthLimit: 5)
        XCTAssertEqual(split, [0 ..< 1, 1 ..< 2])
    }
}

private extension Lines where Element == Weight {
    init(elements: S, spacing: Weight = .zero) {
        self.init(elements: elements, spacing: spacing, length: { $0 })
    }
}
